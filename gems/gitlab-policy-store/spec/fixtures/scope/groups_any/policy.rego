package gitlab.scope

# policy "Scoped to groups (any)" (match_mode: any)

default excluded := false

default included := false

included if {
	some group_id in input.groups
	group_id in {10}
}

included if {
	some business_impact_id in input.security_attributes.business_impact
	business_impact_id in {1}
}

default applies := false

applies if {
	not excluded
	included
}
