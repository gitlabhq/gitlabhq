GenericIssueField.seed(:id, [
  { :id => 1,  :project_id => 2, :title => 'severity', :description => 'how bad is it?',
         :default_value => 3, :mandatory => true },
  { :id => 2,  :project_id => 2, :title => 'component', :description => 'pick the component',
         :default_value => 7, :mandatory => false }
])

GenericIssueFieldValue.seed(:id, [
 { :id => 1, :generic_issue_field_id => 1, :title => 'enhancement', :description => 'no bug'},
 { :id => 2, :generic_issue_field_id => 1, :title => 'minor' , :description => 'a trivial flaw'},
 { :id => 3, :generic_issue_field_id => 1, :title => 'major', :description => 'a normal bug' },
 { :id => 4, :generic_issue_field_id => 1, :title => 'blocker', :description => 'something very bad' },
 { :id => 5, :generic_issue_field_id => 1, :title => 'critical' , :description => 'a crash or security thing' },
 { :id => 6, :generic_issue_field_id => 2, :title => 'algebra',  :description => ''},
 { :id => 7, :generic_issue_field_id => 2, :title => 'packages' , :description => ''},
 { :id => 8, :generic_issue_field_id => 2, :title => 'geometry', :description => '' }
])

IssueGenericIssueFieldValue.seed(:generic_issue_field_value_id, [
 { :issue_id => 1, :generic_issue_field_value_id => 2 },
 { :issue_id => 1, :generic_issue_field_value_id => 6 },
 { :issue_id => 2, :generic_issue_field_value_id => 1 },
 { :issue_id => 2, :generic_issue_field_value_id => 8 }
])
