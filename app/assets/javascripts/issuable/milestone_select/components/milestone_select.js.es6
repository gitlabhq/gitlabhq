((gl) => {
  Vue.component('issuable-milestone-select', {
    props: ['admin', 'milestone'],
    computed: {
      hasMilestone() {
        return !!this.milestone;
      }
    },
    methods: {
      removeMilestone() {
        console.log("Removed Due Date")
      },
      editMilestone() {
        console.log("Edit due date");
      }
    },
    mounted() {
      console.log("Init GL Dropdown or Droplab");
    },
    template: `
    
  `
  });

 /**
  * 
   .block.milestone
          .sidebar-collapsed-icon
            = icon('clock-o')
            %span
              - if issuable.milestone
                %span.has-tooltip{title: milestone_remaining_days(issuable.milestone), data: {container: 'body', html: 1, placement: 'left'}}
                  = issuable.milestone.title
              - else
                None
          .title.hide-collapsed
            Milestone
            = icon('spinner spin', class: 'block-loading')
            - if can_edit_issuable
              = link_to 'Edit', '#', class: 'edit-link pull-right'
          .value.hide-collapsed
            - if issuable.milestone
              = link_to issuable.milestone.title, namespace_project_milestone_path(@project.namespace, @project, issuable.milestone), class: "bold has-tooltip", title: milestone_remaining_days(issuable.milestone), data: { container: "body", html: 1 }
            - else
              %span.no-value None

          .selectbox.hide-collapsed
            = f.hidden_field 'milestone_id', value: issuable.milestone_id, id: nil
            = dropdown_tag('Milestone', options: { title: 'Assign milestone', toggle_class: 'js-milestone-select js-extra-options', filter: true, dropdown_class: 'dropdown-menu-selectable', placeholder: 'Search milestones', data: { show_no: true, field_name: "#{issuable.to_ability_name}[milestone_id]", project_id: @project.id, issuable_id: issuable.id, milestones: namespace_project_milestones_path(@project.namespace, @project, :json), ability_name: issuable.to_ability_name, issue_update: issuable_json_path(issuable), use_id: true }})




  */

})(window.gl || (window.gl = {}));
