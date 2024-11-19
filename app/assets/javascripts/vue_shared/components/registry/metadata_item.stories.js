import MetadataItem from './metadata_item.vue';

export default {
  component: MetadataItem,
  title: 'vue_shared/registry/metadata-item',
  argTypes: {
    icon: {
      control: 'text',
      description: 'Icon name from GitLab UI to display alongside text',
    },
    text: {
      control: 'text',
      description: 'Main text content for the metadata item',
    },
    link: {
      control: 'text',
      description: 'URL to link text to, if applicable',
    },
    size: {
      control: { type: 'select', options: ['s', 'm', 'l', 'xl'] },
      description: 'Max width of the component',
    },
    textTooltip: {
      control: 'text',
      description: 'Tooltip text to show on hover when text is truncated',
    },
  },
};

// Default story for displaying basic text without icon or link
export const Default = (args) => ({
  components: { MetadataItem },
  setup() {
    return { args };
  },
  template: '<MetadataItem v-bind="args" />',
});
Default.args = {
  text: 'Metadata item text',
};

// Story for displaying metadata item with an icon
export const WithIcon = (args) => ({
  components: { MetadataItem },
  setup() {
    return { args };
  },
  template: '<MetadataItem v-bind="args" />',
});
WithIcon.args = {
  icon: 'clock',
  text: 'With icon example',
};

// Story for displaying metadata item as a link
export const WithLink = (args) => ({
  components: { MetadataItem },
  setup() {
    return { args };
  },
  template: '<MetadataItem v-bind="args" />',
});
WithLink.args = {
  text: 'GitLab Documentation',
  link: '#',
};

// Story for metadata item with a tooltip on truncated text
export const WithTooltipOnTruncate = (args) => ({
  components: { MetadataItem },
  setup() {
    return { args };
  },
  template: '<MetadataItem v-bind="args" />',
});
WithTooltipOnTruncate.args = {
  text: 'This is a very long piece of metadata text that might be truncated.',
  textTooltip: 'Detailed description of the metadata',
};

// Story for varying text sizes
export const VaryingSizes = (args) => ({
  components: { MetadataItem },
  setup() {
    return { args };
  },
  template: `
    <div class='gl-flex gl-flex-col'>
      <MetadataItem :text="'Size S: '+args.text" size="s"  />
      <MetadataItem :text="'Size M: '+args.text" size="m"  />
      <MetadataItem :text="'Size L: '+args.text" size="l"  />
      <MetadataItem :text="'Size XL: '+args.text" size="xl"  />
    </div>
  `,
});
VaryingSizes.args = {
  text: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
};
