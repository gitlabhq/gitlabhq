module Grack
  module Helpers
    def project_by_path(path)
      if m = /^([\w\.\/-]+)\.git/.match(path).to_a
        path_with_namespace = m.last
        path_with_namespace.gsub!(/\.wiki$/, '')

        Project.find_with_namespace(path_with_namespace)
      end
    end

    def render_not_found
      [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
    end

    def can?(object, action, subject)
      abilities.allowed?(object, action, subject)
    end

    def abilities
      @abilities ||= begin
                       abilities = Six.new
                       abilities << Ability
                       abilities
                     end
    end
  end
end
