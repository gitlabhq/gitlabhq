#Orphan Issues Collector acount created
orphan_issues_collector = User.create(
	email:"orphan_issues_collector@local.host",
	name:"Orphan Issues Collector",
	username:"orphan_issues_collector",
	password:"e116b9f41068a8f4b33c2",
	password_confirmation:"e116b9f41068a8f4b33c2"
)

orphan_issues_collector.state = "blocked"
orphan_issues_collector.projects_limit = 0
orphan_issues_collector.save!

