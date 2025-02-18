import { GlBadge, GlIcon } from '@gitlab/ui';
import MultipleChoiceSelector from './multiple_choice_selector.vue';
import MultipleChoiceSelectorItem from './multiple_choice_selector_item.vue';

export default {
  component: MultipleChoiceSelector,
  title: 'vue_shared/multiple_choice_selector',
};

const data = () => ({
  selected: ['option', 'option-two'],
});

const Template = () => ({
  components: { MultipleChoiceSelector, MultipleChoiceSelectorItem, GlBadge, GlIcon },
  data,
  template: `<multiple-choice-selector :selected="selected">
    <multiple-choice-selector-item value="option" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="false"></multiple-choice-selector-item>
    <multiple-choice-selector-item value="option-two" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="false"></multiple-choice-selector-item>
    <multiple-choice-selector-item value="option-3" description="This is a description for this option. Descriptions are optional." :disabled="false">
      Option name
      <gl-badge variant="muted">Beta</gl-badge>
      <div class="gl-flex gl-gap-2">
        <gl-icon name="tanuki" />
        <gl-icon name="github" />
        <gl-icon name="bitbucket" />
        <gl-icon name="gitea" />
      </div>
    </multiple-choice-selector-item>
    <multiple-choice-selector-item value="option-4" title="Option name" description="This is a description for this option. Descriptions are optional." :disabled="true" disabledMessage="This option is only available in other cases"></multiple-choice-selector-item>
  </multiple-choice-selector>`,
});

export const Default = Template.bind({});
