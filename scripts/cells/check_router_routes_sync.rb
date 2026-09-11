#!/usr/bin/env ruby
# frozen_string_literal: true

# Compares the HTTP Router's committed routing snapshot with this branch's.
#
# GitLab owns config/routing/gitlab_routes.json. The HTTP Router mirrors it at
# test/routes/gitlab_routes.json and replays every example against its own
# routing table, so a route GitLab knows about and the router does not can be
# classified to the wrong cell.
#
# Exit codes are distinct so CI can treat a download problem differently from
# real drift:
#
#   0  in sync
#   1  the two snapshots differ
#   2  the router's snapshot could not be downloaded, or was not a snapshot
#
# Overridable for local runs and fork branches:
#
#   CELLS_ROUTER_PROJECT       default gitlab-org/cells/http-router
#   CELLS_ROUTER_REF           default main
#   CELLS_ROUTER_SNAPSHOT_URL  bypasses both of the above
#
# Runs on plain Ruby with no bundle: the gem it loads has no runtime
# dependencies, so the CI job needs no gems and can run with `needs: []`.

require "net/http"
require "openssl"
require "uri"
require "open3"
require "tmpdir"

require_relative "../../gems/gitlab-cells-http_router/lib/gitlab/cells/http_router"

module CheckRouterRoutesSync
  LOCAL_SNAPSHOT = "config/routing/gitlab_routes.json"
  ROUTER_SNAPSHOT = "test/routes/gitlab_routes.json"
  DOCS_URL = "https://docs.gitlab.com/development/cells/http_router/#check-the-http-router-is-in-sync"
  SKIP_LABEL = "pipeline:skip-router-sync"

  MAX_LISTED_TEMPLATES = 20
  MAX_DIFF_LINES = 100
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 60
  MAX_ATTEMPTS = 3

  IN_SYNC = 0
  DRIFT = 1
  DOWNLOAD_FAILED = 2

  # Worth retrying: a transport error or a 5xx. A 404 is a wrong ref, which
  # retrying cannot fix, so it raises DownloadError directly.
  DownloadError = Class.new(StandardError)
  RetryableDownloadError = Class.new(DownloadError)

  TRANSPORT_ERRORS = [
    Timeout::Error, SystemCallError, SocketError, Net::HTTPBadResponse, OpenSSL::SSL::SSLError
  ].freeze

  class << self
    def run
      local_payload = read_local_snapshot
      return report_missing_local unless local_payload

      router_payload = download

      comparison = Gitlab::Cells::HttpRouter::SnapshotComparison.new(
        gitlab_payload: local_payload,
        router_payload: router_payload
      )

      return report_in_sync if comparison.identical?

      report_drift(comparison, local_payload, router_payload)
      DRIFT
    rescue Gitlab::Cells::HttpRouter::SnapshotComparison::InvalidSnapshotError => e
      warn "cells-routes: #{e.message}"
      e.source == :router ? report_download_failed : report_invalid_local
    rescue DownloadError => e
      warn "cells-routes: #{e.message}"
      report_download_failed
    end

    private

    def repo_root
      @repo_root ||= File.expand_path("../..", __dir__)
    end

    def local_path
      File.join(repo_root, LOCAL_SNAPSHOT)
    end

    # Rescues here, not around run: a stray ENOENT from anywhere else must not
    # read as a missing snapshot.
    def read_local_snapshot
      File.read(local_path)
    rescue Errno::ENOENT
      nil
    end

    def snapshot_url
      @snapshot_url ||= ENV["CELLS_ROUTER_SNAPSHOT_URL"] || begin
        project = ENV["CELLS_ROUTER_PROJECT"] || "gitlab-org/cells/http-router"
        ref = ENV["CELLS_ROUTER_REF"] || "main"

        "https://gitlab.com/#{project}/-/raw/#{ref}/#{ROUTER_SNAPSHOT}"
      end
    end

    def download
      attempt = 0

      begin
        attempt += 1
        fetch(URI.parse(snapshot_url))
      rescue RetryableDownloadError, *TRANSPORT_ERRORS => e
        raise DownloadError, "could not download #{snapshot_url}: #{e.message}" if attempt >= MAX_ATTEMPTS

        sleep(attempt)
        retry
      end
    end

    def fetch(uri)
      response = Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: OPEN_TIMEOUT,
        read_timeout: READ_TIMEOUT
      ) { |http| http.request(Net::HTTP::Get.new(uri)) }

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPServerError
        raise RetryableDownloadError, "#{snapshot_url} returned HTTP #{response.code}"
      else
        raise DownloadError, "#{snapshot_url} returned HTTP #{response.code} #{response.message}"
      end
    end

    def report_in_sync
      puts "cells-routes: #{snapshot_url}"
      puts "cells-routes: matches #{LOCAL_SNAPSHOT} on this branch."
      IN_SYNC
    end

    def report_missing_local
      warn "cells-routes: #{LOCAL_SNAPSHOT} does not exist."
      warn "cells-routes: run 'bundle exec rake gitlab:cells:routes:generate' and commit the result."
      DRIFT
    end

    def report_invalid_local
      warn <<~MESSAGE

        The problem is #{LOCAL_SNAPSHOT} on this branch, not the download. It is not a
        routing snapshot, so nothing was compared. Run
        'bundle exec rake gitlab:cells:routes:generate' and commit the result.
      MESSAGE

      DRIFT
    end

    def report_download_failed
      warn <<~MESSAGE

        DOWNLOAD FAILED - this is not route drift.

        The HTTP Router's snapshot could not be downloaded, so nothing was compared. Your
        routes are fine and no HTTP Router merge request is needed. Retry the job; this check
        does not block the merge.
      MESSAGE

      DOWNLOAD_FAILED
    end

    def report_drift(comparison, local_payload, router_payload)
      warn "cells-routes: #{snapshot_url}"
      warn "cells-routes: does not match #{LOCAL_SNAPSHOT} on this branch."

      report_side(comparison.gitlab_only, "exist only in GitLab (the router has not seen them)")
      report_side(comparison.router_only, "exist only in the HTTP Router (usually removed from GitLab)")

      if comparison.formatting_only?
        warn ""
        warn "The route templates match. Only the file's formatting or extra per-route fields differ."
      end

      report_diff(local_payload, router_payload)
      warn drift_guidance
    end

    def report_side(templates, label)
      return if templates.empty?

      warn ""
      warn "#{templates.size} route templates #{label}:"
      templates.first(MAX_LISTED_TEMPLATES).each { |template| warn "  #{template}" }

      return unless templates.size > MAX_LISTED_TEMPLATES

      warn "  ... and #{templates.size - MAX_LISTED_TEMPLATES} more"
    end

    # Shells out to diff rather than reimplementing it: the unified format is
    # what a reader expects from a drift report.
    def report_diff(local_payload, router_payload)
      lines = Dir.mktmpdir do |dir|
        router_file = File.join(dir, "router.json")
        local_file = File.join(dir, "gitlab.json")
        File.write(router_file, router_payload)
        File.write(local_file, local_payload)

        stdout, = Open3.capture2("diff", "-u", router_file, local_file)

        # Drops the two header lines, which name the temporary files.
        stdout.lines.drop(2)
      end

      warn ""
      warn "Byte diff, '-' is the HTTP Router and '+' is this branch:"
      lines.first(MAX_DIFF_LINES).each { |line| warn line.chomp }

      warn "... truncated, #{lines.size} diff lines in total" if lines.size > MAX_DIFF_LINES
    end

    def drift_guidance
      <<~MESSAGE

        The HTTP Router's committed route snapshot does not match the routes on this branch.

        Open a paired merge request in gitlab-org/cells/http-router that runs:
          npm run download-gitlab-routes -- <this-branch-name>
        Update the vitest snapshot, merge that request, then re-run this pipeline.

        This check does not block merging yet. To merge anyway, apply the
        #{SKIP_LABEL} label and say why in the merge request description.

        Docs: #{DOCS_URL}
      MESSAGE
    end
  end
end

exit CheckRouterRoutesSync.run if $PROGRAM_NAME == __FILE__
