import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import MilestonePresenter from '~/glql/components/presenters/milestone.vue';
import { MOCK_MILESTONE } from '../../mock_data';

describe('MilestonePresenter', () => {
  let wrapper;

  const createWrapper = ({ data }) => {
    wrapper = shallowMountExtended(MilestonePresenter, {
      propsData: { data },
    });
  };

  const findLink = () => wrapper.findComponent(GlLink);

  it('correctly renders a milestone link', () => {
    createWrapper({ data: MOCK_MILESTONE });

    const link = findLink();

    expect(link.attributes('href')).toContain(MOCK_MILESTONE.webPath);
    expect(link.text()).toBe(`%${MOCK_MILESTONE.title}`);
  });
});
