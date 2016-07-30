class NoteTemplateDropdown {
  constructor(options) {
    this.$dropdown = options.$dropdown;
    this.$textarea = this.$dropdown.parents(".md-area").find("textarea");
    this.buildDropdown();
  }

  buildDropdown() {
    var _this = this;
    this.$dropdown.glDropdown({
      data(term, callback) {
        return $.ajax({
          url: _this.$dropdown.data('note-templates-url'),
          dataType: "json"
        }).done(function(templates) {
          return callback(templates);
        });
      },
      selectable: true,
      filterable: true,
      filterByText: true,
      search: {
        fields: ['note']
      },
      renderRow(template) {
        return _.template('<li><a href="#" class="dropdown-menu-item-with-description"><span class="dropdown-menu-item-header dropdown-menu-note-template-header"><%- title %></span><span class="dropdown-menu-item-body"><%- note %></span></a></li>')({ title: template.title, note: template.note });
      },
      id(obj, $el) {
        return $el.attr('data-note-template');
      },
      clicked(selected, $el, e) {
        e.preventDefault();
        return window.gl.text.updateText(_this.$textarea, selected.note, false, false);
      }
    });
  }
}
