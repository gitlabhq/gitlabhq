module EE
  module Import
    module GithubController
      extend ::Gitlab::Utils::Override

      override :extra_project_attrs
      def extra_project_attrs
        super.merge(ci_cd_only: params[:ci_cd_only])
      end

      override :extra_import_params
      def extra_import_params
        extra_params = super
        extra_params[:ci_cd_only] = true if params[:ci_cd_only].present?

        extra_params
      end
    end
  end
end
