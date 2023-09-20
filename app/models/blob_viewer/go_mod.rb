# frozen_string_literal: true

module BlobViewer
  class GoMod < DependencyManager
    include ServerSide
    include Gitlab::Utils::StrongMemoize

    MODULE_REGEX = %r{
      \A (?# beginning of file)
      module\s+ (?# module directive)
      (?<name>.*?) (?# module name)
      \s*(?://.*)? (?# comment)
      (?:\n|\z) (?# newline or end of file)
    }x

    self.file_types = %i[go_mod go_sum]

    def manager_name
      'Go Modules'
    end

    def manager_url
      'https://golang.org/ref/mod'
    end

    def package_type
      'go'
    end

    def package_name
      strong_memoize(:package_name) do
        next if blob.name != 'go.mod'
        next unless match = MODULE_REGEX.match(blob.data)

        match[:name]
      end
    end

    def package_url
      Gitlab::Golang.package_url(package_name)
    end
  end
end
