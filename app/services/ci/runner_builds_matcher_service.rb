# This class requires that valid_runners_for_pending_build and pending_builds_for_runner are complementary
# One focues on getting runners, the other one on getting builds
# They are highly optimised to be a single SQL query

module Ci
  class RunnerBuildsMatcherService
    def valid_runners_for_pending_build(build)
      runners = build.project.all_runners

      # select only protected runners
      runners = runners.ref_protected if build.ref_protected?

      # pick only untagged runners, or ones containing all our tags
      if build.tag_ids.any?
        runners = runners.contains_all_tag_ids(build.tag_ids)
      else
        runners = runners.run_untagged
      end

      runners
    end

    def pending_builds_for_runner(runner)
      builds = Ci::Build.pending.unstarted

      # get builds only for matching projects
      builds = builds.joins(:project).merge(runner.all_projects)

      # pick only protected builds
      builds = builds.ref_protected if runner.ref_protected?

      # pick builds that does not have other tags than runner's one
      builds = builds.matches_tag_ids(runner.tag_ids)

      # pick builds that have at least one tag
      unless runner.run_untagged?
        builds = builds.with_any_tags
      end

      builds
    end
  end
end
