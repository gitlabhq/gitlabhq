export default {
  props: {
    stopPropagation: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      currentIndex: 0,
      tabs: [],
    };
  },
  mounted() {
    this.updateTabs();
  },
  methods: {
    updateTabs() {
      this.tabs = this.$children.filter(child => child.isTab);
      this.currentIndex = this.tabs.findIndex(tab => tab.localActive);
    },
    setTab(e, index) {
      if (this.stopPropagation) {
        e.stopPropagation();
        e.preventDefault();
      }

      this.tabs[this.currentIndex].localActive = false;
      this.tabs[index].localActive = true;

      this.currentIndex = index;
    },
  },
  render(h) {
    const navItems = this.tabs.map((tab, i) =>
      h(
        'li',
        {
          key: i,
        },
        [
          h(
            'a',
            {
              class: tab.localActive ? 'active' : null,
              attrs: {
                href: '#',
              },
              on: {
                click: e => this.setTab(e, i),
              },
            },
            tab.$slots.title || tab.title,
          ),
        ],
      ),
    );
    const nav = h(
      'ul',
      {
        class: 'nav-links tab-links',
      },
      [navItems],
    );
    const content = h(
      'div',
      {
        class: ['tab-content'],
      },
      [this.$slots.default],
    );

    return h('div', {}, [[nav], content]);
  },
};
