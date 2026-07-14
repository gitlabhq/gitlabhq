# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Rewrites source-relative Markdown links in distilled output to absolute
      # docs.gitlab.com URLs.
      #
      # The distillation agent copies links verbatim from the SSOT documents. A
      # relative link like `../../user/gitlab_duo/feature_summary.md` resolves
      # correctly from its source file (under `doc/...`), but distilled files
      # live under `.ai/principles/distilled/`, so the same relative path points
      # at a nonexistent file. Resolving each relative link against the SSOT
      # source directories and rewriting it to the canonical published URL keeps
      # the references valid for both AI agents and human readers.
      module Links
        extend self

        DOCS_BASE = 'https://docs.gitlab.com'

        # Markdown inline link whose target is not already absolute and not an
        # in-document anchor. Captures the link text, the path portion, and an
        # optional `#anchor` fragment separately so the fragment is preserved.
        LINK_PATTERN = %r{
          \[(?<text>[^\]]*)\]
          \((?<path>(?:\./|\.\./|\w[\w./-]*)[\w./-]*?\.md)(?<anchor>\#[^)]*)?\)
        }x

        # Doc-tree prefixes that map onto the published docs site root.
        DOC_PREFIXES = ['doc/', 'ee/doc/'].freeze

        # Rewrites relative `.md` links in `content` to absolute docs URLs.
        #
        # `sources` is the principle's manifest `sources:` array (entries with a
        # `'path'` key). Each relative link is resolved against every source
        # file's directory; the first candidate that lands under a doc tree and
        # exists is used. Already-absolute links, in-document anchors, and links
        # that cannot be resolved are left untouched.
        #
        # `exist` is an injectable predicate (repo_path -> Boolean) so callers
        # can supply the workspace-aware lookup; tests pass a stub. When omitted,
        # every doc-tree candidate is accepted without an existence check.
        def absolutize(content, sources:, exist: nil, warn_unresolved: nil)
          source_dirs = source_directories(sources)

          content.gsub(LINK_PATTERN) do
            match = Regexp.last_match
            text = match[:text]
            rel_path = match[:path]
            anchor = match[:anchor].to_s

            url = resolve(rel_path, source_dirs, exist)

            if url
              "[#{text}](#{url}#{anchor})"
            else
              warn_unresolved&.call(rel_path)
              match[0]
            end
          end
        end

        private

        def source_directories(sources)
          Array(sources).filter_map { |s| s['path'] }.map { |path| File.dirname(path) }.uniq
        end

        # Resolves `rel_path` against each source directory, returning the
        # canonical docs URL for the first doc-tree candidate that exists (or, if
        # no existence predicate is supplied, the first doc-tree candidate).
        def resolve(rel_path, source_dirs, exist)
          source_dirs.each do |dir|
            candidate = normalize(File.join(dir, rel_path))
            next unless doc_tree?(candidate)
            next if exist && !exist.call(candidate)

            return to_docs_url(candidate)
          end

          nil
        end

        # Collapses `.`/`..` segments without touching the filesystem. Pure
        # lexical normalization so it stays deterministic across machines.
        def normalize(path)
          segments = []
          path.split('/').each do |segment|
            case segment
            when '.', ''
              next
            when '..'
              segments.pop
            else
              segments << segment
            end
          end
          segments.join('/')
        end

        def doc_tree?(path)
          DOC_PREFIXES.any? { |prefix| path.start_with?(prefix) }
        end

        def to_docs_url(path)
          prefix = DOC_PREFIXES.find { |p| path.start_with?(p) }
          canonical = path.delete_prefix(prefix)
          canonical =
            if canonical == '_index.md'
              # A doc-prefix root (e.g. `doc/_index.md`) maps to the site root,
              # not `/_index/`.
              ''
            else
              canonical.delete_suffix('/_index.md').delete_suffix('.md')
            end

          canonical.empty? ? "#{DOCS_BASE}/" : "#{DOCS_BASE}/#{canonical}/"
        end
      end
    end
  end
end
