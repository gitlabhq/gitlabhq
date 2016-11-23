  // - project_ref = cross_project_reference(@project, issuable)
  //     .block.project-reference
  //       .sidebar-collapsed-icon.dont-change-state
  //         = clipboard_button(clipboard_text: project_ref)
  //       .cross-project-reference.hide-collapsed
  //         %span
  //           Reference:
  //           %cite{title: project_ref}
  //             = project_ref
  //         = clipboard_button(clipboard_text: project_ref)