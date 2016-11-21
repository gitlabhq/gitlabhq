class IssueEntity < IssuableEntity
  expose :branch_name
  expose :confidential
  expose :due_date
  expose :moved_to_id
  expose :project_id
<<<<<<< HEAD
  expose :weight
=======
>>>>>>> ce/master
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
end
