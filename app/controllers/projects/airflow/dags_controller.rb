# frozen_string_literal: true

module Projects
  module Airflow
    class DagsController < ::Projects::ApplicationController
      before_action :check_feature_flag
      before_action :authorize_read_airflow_dags!

      feature_category :dataops

      MAX_DAGS_PER_PAGE = 15
      def index
        page = params[:page].to_i
        page = 1 if page <= 0

        @dags = ::Airflow::Dags.by_project_id(@project.id)

        return unless @dags.any?

        @dags = @dags.page(page).per(MAX_DAGS_PER_PAGE)
        return redirect_to(url_for(page: @dags.total_pages)) if @dags.out_of_range?

        @pagination = {
          page: page,
          is_last_page: @dags.last_page?,
          per_page: MAX_DAGS_PER_PAGE,
          total_items: @dags.total_count
        }
      end

      private

      def check_feature_flag
        render_404 unless Feature.enabled?(:airflow_dags, @project)
      end
    end
  end
end
