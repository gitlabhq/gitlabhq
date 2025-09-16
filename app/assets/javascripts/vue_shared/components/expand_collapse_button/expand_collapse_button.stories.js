import { GlCard } from '@gitlab/ui';
import ExpandCollapseButton from './expand_collapse_button.vue';

export default {
  component: ExpandCollapseButton,
  title: 'vue_shared/expand_collapse_button',
};

const Template = (args, { argTypes }) => ({
  components: { ExpandCollapseButton },
  props: Object.keys(argTypes),
  template: `
    <expand-collapse-button v-bind="$props"/>
  `,
});

export const Default = Template.bind({});
Default.args = {
  isCollapsed: true,
  anchorId: '',
  size: 'small',
};
export const MultipleSections = (args, { argTypes }) => ({
  components: { ExpandCollapseButton, GlCard },
  props: Object.keys(argTypes),
  data() {
    return {
      sections: [
        { id: 'section1', collapsed: true, title: 'Section 1', content: 'Content for section 1' },
        { id: 'section2', collapsed: false, title: 'Section 2', content: 'Content for section 2' },
        { id: 'section3', collapsed: true, title: 'Section 3', content: 'Content for section 3' },
      ],
    };
  },
  template: `
    <div>
      <h3>Multiple Expand/Collapse Buttons</h3>
      <gl-card v-for="section in sections" :key="section.id" :body-class="section.collapsed ? 'gl-hidden' : ''" class="gl-mb-4">
        <template #header>
          <div class="gl-flex gl-items-center gl-p-4">
            <h4 class="gl-m-0 gl-flex-1">{{ section.title }}</h4>
            <expand-collapse-button
              :is-collapsed="section.collapsed"
              :anchor-id="section.id + '-content'"
              size="small"
              @click="section.collapsed = !section.collapsed"
            />
          </div>
        </template>

        <template v-if="!section.collapsed" #default>
          <div class="gl-p-4">
            {{ section.content }}
          </div>
        </template>
      </gl-card>
    </div>
  `,
});
MultipleSections.args = {};
