import HelpPopover from './help_popover.vue';

export default {
  component: HelpPopover,
  title: 'vue_shared/help_popover',
};

const defaultOptions = {
  title: 'Help Title',
  content: 'This is some helpful content explaining a feature.',
  placement: 'top',
};

const defaultArgs = {
  options: { ...defaultOptions },
  icon: 'question-o',
  triggerClass: '',
  ariaLabel: 'Help',
};

const Template = (args, { argTypes }) => ({
  components: { HelpPopover },
  props: Object.keys(argTypes),
  template: `<div style="padding: 100px; text-align: center;"><help-popover v-bind="$props" /></div>`,
});

export const Default = Template.bind({});
Default.args = {
  ...defaultArgs,
};

export const CustomIcon = Template.bind({});
CustomIcon.args = {
  ...defaultArgs,
  icon: 'information-o',
};

export const CustomAriaLabel = Template.bind({});
CustomAriaLabel.args = {
  ...defaultArgs,
  ariaLabel: 'Custom help text',
};

export const TitleOnly = Template.bind({});
TitleOnly.args = {
  ...defaultArgs,
  options: {
    title: 'Title Only Popover',
    placement: 'top',
  },
};

export const ContentOnly = Template.bind({});
ContentOnly.args = {
  ...defaultArgs,
  options: {
    content: 'Content Only Popover',
    placement: 'top',
  },
};

export const HtmlContent = Template.bind({});
HtmlContent.args = {
  ...defaultArgs,
  options: {
    title: '<strong>HTML Title</strong>',
    content: 'Content with <em>HTML</em> and <a href="#">link</a>',
    placement: 'top',
  },
};

export const DifferentPlacement = Template.bind({});
DifferentPlacement.args = {
  ...defaultArgs,
  options: {
    ...defaultOptions,
    placement: 'bottom',
  },
};

export const WithCustomSlot = (args, { argTypes }) => ({
  components: { HelpPopover },
  props: Object.keys(argTypes),
  template: `<div style="padding: 100px; text-align: center;"><help-popover v-bind="$props"><template #footer><div style="margin-top: 8px; padding-top: 8px; border-top: 1px solid #eee;">             <a href="#">Learn more</a>           </div>         </template>       </help-popover>     </div> `,
});
WithCustomSlot.args = {
  ...defaultArgs,
};

export const WithAdditionalOptions = Template.bind({});
WithAdditionalOptions.args = {
  ...defaultArgs,
  options: {
    ...defaultOptions,
    container: 'body',
    triggers: 'click',
    boundary: 'viewport',
  },
};
