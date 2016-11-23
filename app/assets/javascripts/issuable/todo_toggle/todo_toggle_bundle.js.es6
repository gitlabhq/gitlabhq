// .block.issuable-sidebar-header
//       - if current_user
//         %span.issuable-header-text.hide-collapsed.pull-left
//           Todo
//       %a.gutter-toggle.pull-right.js-sidebar-toggle{ role: "button", href: "#", aria: { label: "Toggle sidebar" } }
//         = sidebar_gutter_toggle_icon
//       - if current_user
//         %button.btn.btn-default.issuable-header-btn.pull-right.js-issuable-todo{ type: "button", aria: { label: (todo.nil? ? "Add Todo" : "Mark Done") }, data: { todo_text: "Add Todo", mark_text: "Mark Done", issuable_id: issuable.id, issuable_type: issuable.class.name.underscore, url: namespace_project_todos_path(@project.namespace, @project), delete_path: (dashboard_todo_path(todo) if todo) } }
//           %span.js-issuable-todo-text
//             - if todo
//               Mark Done
//             - else
//               Add Todo
//           = icon('spin spinner', class: 'hidden js-issuable-todo-loading')
