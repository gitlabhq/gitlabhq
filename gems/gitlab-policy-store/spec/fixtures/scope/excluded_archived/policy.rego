package gitlab.scope

# policy "Excluding archived projects" (match_mode: all)

default excluded := false

excluded if {
	input.project.archived == true
}

default included := false

included if { true }

default applies := false

applies if {
	not excluded
	included
}
