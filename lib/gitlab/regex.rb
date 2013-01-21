module Gitlab
  module Regex
    extend self

    def username_regex
      default_regex
    end

    def project_name_regex
      /\A[a-zA-Z][a-zA-Z0-9_\-\. ]*\z/
    end

    def path_regex
      default_regex
    end

    protected

    def default_regex
      /\A[a-zA-Z][a-zA-Z0-9_\-\.]*\z/
    end
  end
end
