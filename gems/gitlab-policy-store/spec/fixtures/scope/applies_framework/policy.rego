package gitlab.scope

# policy "Scoped to compliance framework 5" (match_mode: all)

default excluded := false

excluded if {
	input.project.archived == true
}

default included := false

included if {
	some framework_id in input.compliance_frameworks
	framework_id in {5}
}

default applies := false

applies if {
	not excluded
	included
}
