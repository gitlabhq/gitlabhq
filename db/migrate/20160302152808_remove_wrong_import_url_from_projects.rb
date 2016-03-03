class RemoveWrongImportUrlFromProjects < ActiveRecord::Migration

  class ImportUrlSanitizer
    def initialize(url)
      @url = url
    end

    def sanitized_url
      @sanitized_url ||= @url[regex_extractor, 1] + @url[regex_extractor, 3]
    end

    def credentials
      @credentials ||= @url[regex_extractor, 2]
    end

    private

    # Regex matches 1 <first part of URL>, 2 <token or to be encrypted stuff>,
    # 3 <last part of URL>
    def regex_extractor
      /(.*\/\/)(.*)(\@.*)/
    end
  end

  def up
    projects_with_wrong_import_url.each do |project|
      sanitizer = ImportUrlSanitizer.new(project.import_urls)
      project.update_columns(import_url: sanitizer.sanitized_url)
      if project.import_data
        project.import_data.update_columns(credentials: sanitizer.credentials)
      end
    end
  end

  def projects_with_wrong_import_url
    # TODO Check live with #operations for possible false positives. Also, consider regex? But may have issues MySQL/PSQL
    select_all("SELECT p.id from projects p WHERE p.import_url LIKE '%//%:%@%' or p.import_url like '#{"_"*40}@github.com%'")
  end
end
