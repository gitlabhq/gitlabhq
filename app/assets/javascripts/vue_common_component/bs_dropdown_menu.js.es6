(() => {
  Vue.component('bs-dropdown-menu', {
    props: {
      classNames: {
        type: String,
        required: false,
        default: '',
      },
      title: {
        type: String,
        required: false,
        default: '',
      },
      filter: {
        type: Boolean,
        required: false,
        default: false,
      },
      filterPlaceholder: {
        type: String,
        required: false,
        default: '',
      },
      selectable: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    template: `
      <div
        class="dropdown-menu"
        :class="classNamesObject">
        <div
          class="dropdown-title"
          v-if="title">
          {{ title }}
        </div>
        <div
          class="dropdown-input"
          v-if="filter">
          <input
            type="search"
            class="dropdown-input-field"
            placeholder="filterPlaceholder"
            autocomplete="off" />
          <i class="fa fa-search dropdown-input-search"></i>
          <i
            class="fa fa-times dropdown-input-clear js-dropdown-input-clear"
            role="button"></i>
        </div>
        <div class="dropdown-content"></div>
        <div class="dropdown-loading">
          <i class="fa fa-spinner fa-spin"></i>
        </div>
      </div>
    `,
    computed: {
      classNamesObject() {
        const classNamesObject = {
          'dropdown-menu-selectable': this.selectable,
        };
        const splitClassNames = this.classNames.split(' ');

        splitClassNames.forEach((className) => {
          classNamesObject[className] = true;
        });

        return classNamesObject;
      },
    },
  })
})();
