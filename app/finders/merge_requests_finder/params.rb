# frozen_string_literal: true

class MergeRequestsFinder
  class Params < IssuableFinder::Params
    def filter_by_no_reviewer?
      params[:reviewer_id].to_s.downcase == FILTER_NONE
    end

    def filter_by_any_reviewer?
      params[:reviewer_id].to_s.downcase == FILTER_ANY
    end

    def reviewer
      strong_memoize(:reviewer) do
        if reviewer_id?
          User.find_by_id(params[:reviewer_id])
        elsif reviewer_username?
          User.find_by_username(params[:reviewer_username])
        end
      end
    end
  end
end
