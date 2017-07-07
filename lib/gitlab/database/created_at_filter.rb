module Gitlab
  module Database
    module CreatedAtFilter
      def by_created_at(items)
        if params[:created_after].present?
          items = items.where(items.klass.arel_table[:created_at].gteq(params[:created_after]))
        end

        if params[:created_before].present?
          items = items.where(items.klass.arel_table[:created_at].lteq(params[:created_before]))
        end

        items
      end
    end
  end
end
