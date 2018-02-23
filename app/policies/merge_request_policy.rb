class MergeRequestPolicy < IssuablePolicy
<<<<<<< HEAD
  prepend EE::MergeRequestPolicy

=======
>>>>>>> upstream/master
  rule { can?(:read_merge_request) | visible_to_user }.enable :read_merge_request_iid
end
