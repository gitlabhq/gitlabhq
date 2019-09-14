import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import MilestoneList from '~/releases/components/milestone_list.vue';
import Icon from '~/vue_shared/components/icon.vue';
import _ from 'underscore';
import { milestones } from '../mock_data';

describe('Milestone list', () => {
  let wrapper;

  const factory = milestonesProp => {
    wrapper = shallowMount(MilestoneList, {
      propsData: {
        milestones: milestonesProp,
      },
      sync: false,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the milestone icon', () => {
    factory(milestones);

    expect(wrapper.find(Icon).exists()).toBe(true);
  });

  it('renders the label as "Milestone" if only a single milestone is passed in', () => {
    factory(milestones.slice(0, 1));

    expect(wrapper.find('.js-label-text').text()).toEqual('Milestone');
  });

  it('renders the label as "Milestones" if more than one milestone is passed in', () => {
    factory(milestones);

    expect(wrapper.find('.js-label-text').text()).toEqual('Milestones');
  });

  it('renders a link to the milestone with a tooltip', () => {
    const milestone = _.first(milestones);
    factory([milestone]);

    const milestoneLink = wrapper.find(GlLink);

    expect(milestoneLink.exists()).toBe(true);

    expect(milestoneLink.text()).toBe(milestone.title);

    expect(milestoneLink.attributes('href')).toBe(milestone.web_url);

    expect(milestoneLink.attributes('data-original-title')).toBe(milestone.description);
  });
});
