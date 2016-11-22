((gl) => {
  Vue.component('issuable-due-date-select', {
    props: ['admin', 'due_date'],
    computed: {
      hasDueDate() {
        return !!this.due_date;
      },
      dueDateHuman() {
        return gl.utils.formatDateNoTime(this.due_date);
      }
    },
    methods: {
      removeDueDate() {
        console.log("Removed Due Date")
      },
      editDueDate() {
        console.log("Edit due date");
      }
    },
    mounted() {
      console.log("Init GL Dropdown or Droplab");
    },
    template: `
    <div class='block due_date'>
      <div class='sidebar-collapsed-icon'>
        <i class='fa fa-calendar'></i>
        <span v-if='hasDueDate'> {{ dueDateHuman }} </span>
        <span v-if='!hasDueDate'> No due date </span>
      </div>
      <div class='title hide-collapsed'> 
        Due date
        <a v-if='admin' href='#' class='edit-link pull-right' @click='editDueDate'>Edit</a>
      </div>
      <div class='value-content hide-collapsed'>
        <span class='bold' v-if='hasDueDate'>{{ dueDateHuman }}</span>
        <span class='no-value' v-if='!hasDueDate'> No due date </span>
        <a href='#' role="button" v-if='admin' @click='removeDueDate'>remove due date</a>
      </div>
      <div class='selectbox hide-collapsed' v-if='admin'>
        Dropdown Select (INSERT DROPLAB)
      </div>
    </div>
  `
  });

  /**
   * 
   * .block.due_date
      - if can?(current_user, :"admin_#{issuable.to_ability_name}", @project)
        .selectbox.hide-collapsed
          = f.hidden_field :due_date, value: issuable.due_date
          .dropdown
            %button.dropdown-menu-toggle.js-due-date-select{ type: 'button', data: { toggle: 'dropdown', 
              field_name: "#{issuable.to_ability_name}[due_date]", ability_name: issuable.to_ability_name, issue_update: issuable_json_path(issuable) } }
              %span.dropdown-toggle-text Due date
              = icon('chevron-down')
            .dropdown-menu.dropdown-menu-due-date
              = dropdown_title('Due date')
              = dropdown_content do
                .js-due-date-calendar
  
   */

})(window.gl || (window.gl = {}));
