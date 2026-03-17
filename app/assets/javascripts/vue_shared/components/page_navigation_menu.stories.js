import PageNavigationMenu from './page_navigation_menu.vue';

export default {
  component: PageNavigationMenu,
  title: 'vue_shared/page_navigation_menu',
};

const Template = (args, { argTypes }) => ({
  components: { PageNavigationMenu },
  props: Object.keys(argTypes),
  template: `
    <div style="display: flex; gap: 20px;">
      <div style="flex: 1; padding: 20px; background: #f5f5f5;">
        <h2 id="section-1">Section 1</h2>
        <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.</p>
        <p>Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.</p>

        <h2 id="section-2" style="margin-top: 40px;">Section 2</h2>
        <p>Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.</p>
        <p>Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.</p>

        <h2 id="section-3" style="margin-top: 40px;">Section 3</h2>
        <p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium.</p>
        <p>Totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.</p>

        <h2 id="section-4" style="margin-top: 40px;">Section 4</h2>
        <p>Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit.</p>
        <p>Sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt.</p>
      </div>
      <div style="width: 250px;">
        <page-navigation-menu v-bind="$props" />
      </div>
    </div>
  `,
});

export const Default = Template.bind({});
Default.args = {
  items: [
    { id: 'section-1', label: 'Section 1' },
    { id: 'section-2', label: 'Section 2' },
    { id: 'section-3', label: 'Section 3' },
    { id: 'section-4', label: 'Section 4' },
  ],
};

export const CustomTitle = Template.bind({});
CustomTitle.args = {
  title: 'Table of Contents',
  items: [
    { id: 'section-1', label: 'Introduction' },
    { id: 'section-2', label: 'Getting Started' },
    { id: 'section-3', label: 'Advanced Topics' },
    { id: 'section-4', label: 'Conclusion' },
  ],
};

export const CustomScrollOffset = Template.bind({});
CustomScrollOffset.args = {
  items: [
    { id: 'section-1', label: 'Section 1' },
    { id: 'section-2', label: 'Section 2' },
    { id: 'section-3', label: 'Section 3' },
    { id: 'section-4', label: 'Section 4' },
  ],
  scrollOffset: 200,
};

export const ManyItems = Template.bind({});
ManyItems.args = {
  items: [
    { id: 'section-1', label: 'Introduction' },
    { id: 'section-2', label: 'Prerequisites' },
    { id: 'section-3', label: 'Installation' },
    { id: 'section-4', label: 'Configuration' },
  ],
};

export const CustomAutoUpdateDelay = Template.bind({});
CustomAutoUpdateDelay.args = {
  title: 'Quick Auto-Update',
  items: [
    { id: 'section-1', label: 'Section 1' },
    { id: 'section-2', label: 'Section 2' },
    { id: 'section-3', label: 'Section 3' },
    { id: 'section-4', label: 'Section 4' },
  ],
  autoUpdateDelay: 500,
};
