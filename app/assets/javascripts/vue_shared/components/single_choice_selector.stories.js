import { GlBadge, GlIcon } from '@gitlab/ui';
import SingleChoiceSelector from './single_choice_selector.vue';
import SingleChoiceSelectorItem from './single_choice_selector_item.vue';

export default {
  component: SingleChoiceSelector,
  title: 'vue_shared/single_choice_selector',
};

const data = () => ({
  checked: 'option',
});

const Template = () => ({
  components: { SingleChoiceSelector, SingleChoiceSelectorItem, GlBadge, GlIcon },
  data,
  template: `<single-choice-selector :checked="checked">
    <single-choice-selector-item value="option" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="false"></single-choice-selector-item>
    <single-choice-selector-item value="option-two" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="false"></single-choice-selector-item>
    <single-choice-selector-item value="option-3" description="This is a description for this option. Descriptions are optional." :disabled="false">
      Option name
      <gl-badge variant="muted">Beta</gl-badge>
      <div class="gl-flex gl-gap-2">
        <gl-icon name="tanuki" />
        <gl-icon name="github" />
        <gl-icon name="bitbucket" />
        <gl-icon name="gitea" />
      </div>
    </single-choice-selector-item>
    <single-choice-selector-item value="option-4" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="true" disabledMessage="This option is only available in other cases"></single-choice-selector-item>
  </single-choice-selector>`,
});

export const Default = Template.bind({});
