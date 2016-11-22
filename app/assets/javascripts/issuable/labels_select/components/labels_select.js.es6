((gl) => {
  Vue.component('issuable-labels-select', {
    props: ['admin', 'labels'],
    computed: {
      hasDueDate() {
        return !!this.labels;
      },
      dueDateHuman() {
        return gl.utils.formatDateNoTime(this.labels);
      }
    },
    methods: {
      removeLabel() {
      },
      createLabel() {
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
   *  - selected_labels = issuable.labels
        .block.labels
          .sidebar-collapsed-icon.js-sidebar-labels-tooltip{ title: issuable_labels_tooltip(issuable.labels_array), data: { placement: "left", container: "body" } }
            = icon('tags')
            %span
              = selected_labels.size
          .title.hide-collapsed
            Labels
            = icon('spinner spin', class: 'block-loading')
            - if can_edit_issuable
              = link_to 'Edit', '#', class: 'edit-link pull-right'
          .value.issuable-show-labels.hide-collapsed{ class: ("has-labels" if selected_labels.any?) }
            - if selected_labels.any?
              - selected_labels.each do |label|
                = link_to_label(label, type: issuable.to_ability_name)
            - else
              %span.no-value None
          .selectbox.hide-collapsed
            - selected_labels.each do |label|
              = hidden_field_tag "#{issuable.to_ability_name}[label_names][]", label.id, id: nil
            .dropdown
              %button.dropdown-menu-toggle.js-label-select.js-multiselect.js-label-sidebar-dropdown{type: "button", data: {toggle: "dropdown", default_label: "Labels", field_name: "#{issuable.to_ability_name}[label_names][]", ability_name: issuable.to_ability_name, show_no: "true", show_any: "true", namespace_path: @project.try(:namespace).try(:path), project_path: @project.try(:path), issue_update: issuable_json_path(issuable), labels: (namespace_project_labels_path(@project.namespace, @project, :json) if @project)}}
                %span.dropdown-toggle-text{ class: ("is-default" if selected_labels.empty?)}
                  = multi_label_name(selected_labels, "Labels")
                = icon('chevron-down')
              .dropdown-menu.dropdown-select.dropdown-menu-paging.dropdown-menu-labels.dropdown-menu-selectable
                = render partial: "shared/issuable/label_page_default"
                - if can? current_user, :admin_label, @project and @project
                  = render partial: "shared/issuable/label_page_create"
   * 
   * 
   */

})(window.gl || (window.gl = {}));
