import { nextTick } from 'vue';
import { GlPopover, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import HelpIcon from '~/vue_shared/components/help_icon/help_icon.vue';
import TimelineEventsTagsPopover from '~/issues/show/components/incidents/timeline_events_tags_popover.vue';

describe('TimelineEventsTagsPopover component', () => {
  let wrapper;

  const mountComponent = () => {
    wrapper = shallowMount(TimelineEventsTagsPopover, {
      stubs: {
        GlPopover,
      },
    });
  };

  beforeEach(() => {
    mountComponent();
  });

  const findQuestionIcon = () => wrapper.findComponent(HelpIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findDocumentationLink = () => findPopover().findComponent(GlLink);

  describe('question icon', () => {
    it('should open a popover with a link when hovered', async () => {
      findQuestionIcon().vm.$emit('hover');
      await nextTick();

      expect(findPopover().exists()).toBe(true);
      expect(findDocumentationLink().exists()).toBe(true);
    });
  });

  describe('documentation link', () => {
    it('redirects to a correct documentation page', async () => {
      findQuestionIcon().vm.$emit('hover');
      await nextTick();

      expect(findDocumentationLink().attributes('href')).toBe(
        helpPagePath('operations/incident_management/incident_timeline_events', {
          anchor: 'incident-tags',
        }),
      );
    });
  });
});
