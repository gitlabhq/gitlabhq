class Projects::CycleAnalyticsController < Projects::ApplicationController
  def show
    @metrics = {
      issue: issue
    }
  end

  private

  def issue
    query = <<-HEREDOC
       WITH ordered_data AS (
         SELECT extract(milliseconds FROM (COALESCE(first_associated_with_milestone_at, first_added_to_board_at) - issues.created_at)) AS data_point,
                row_number() over (order by (COALESCE(first_associated_with_milestone_at, first_added_to_board_at) - issues.created_at)) as row_id
         FROM issues
         INNER JOIN issue_metrics ON issue_metrics.issue_id = issues.id
         WHERE COALESCE(first_associated_with_milestone_at, first_added_to_board_at) IS NOT NULL
       ),

       ct AS (
         SELECT count(1) AS ct
         FROM ordered_data
       )

       SELECT avg(data_point) AS median
       FROM ordered_data
       WHERE row_id between (select ct from ct)/2.0 and (select ct from ct)/2.0 + 1;
    HEREDOC

    ActiveRecord::Base.connection.execute(query).to_a.first['median']
  end
end
