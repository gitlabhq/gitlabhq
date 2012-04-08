class Milestone < ActiveRecord::Base
  belongs_to :project
  has_many :issues

  validates_presence_of :project_id
  validates_presence_of :title

  def self.active
    where("due_date > ? ", Date.today)
  end

  def percent_complete
    @percent_complete ||= begin
                            total_i = self.issues.count
                            closed_i = self.issues.closed.count
                            if total_i > 0
                              (closed_i * 100) / total_i
                            else
                              100
                            end
                          rescue => ex
                            0
                          end
  end

  def expires_at
    "expires at #{due_date.stamp("Aug 21, 2011")}" if due_date
  end
end
