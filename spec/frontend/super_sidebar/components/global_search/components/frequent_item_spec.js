import { GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import FrequentItem from '~/super_sidebar/components/global_search/components/frequent_item.vue';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { stubComponent } from 'helpers/stub_component';
import SearchResultHoverLayover from '~/super_sidebar/components/global_search/components/global_search_hover_overlay.vue';

describe('FrequentlyVisitedItem', () => {
  let wrapper;

  const mockItem = {
    id: 123,
    title: 'mockTitle',
    subtitle: 'mockSubtitle',
    avatar: '/mock/avatar.png',
  };

  const createComponent = () => {
    wrapper = shallowMountExtended(FrequentItem, {
      propsData: {
        item: mockItem,
      },
      stubs: {
        GlButton: stubComponent(GlButton, {
          template: '<button type="button" v-on="$listeners"></button>',
        }),
      },
    });
  };

  const findProjectAvatar = () => wrapper.findComponent(ProjectAvatar);
  const findSubtitle = () => wrapper.findByTestId('subtitle');
  const findLayover = () => wrapper.findComponent(SearchResultHoverLayover);

  beforeEach(() => {
    createComponent();
  });

  it('renders the project avatar with the expected props', () => {
    expect(findProjectAvatar().props()).toMatchObject({
      projectId: mockItem.id,
      projectName: mockItem.title,
      projectAvatarUrl: mockItem.avatar,
      size: 32,
    });
  });

  it('renders the title and subtitle', () => {
    expect(wrapper.text()).toContain(mockItem.title);
    expect(findSubtitle().text()).toContain(mockItem.subtitle);
  });

  it('does not render the subtitle if not given', async () => {
    await wrapper.setProps({ item: { ...mockItem, subtitle: null } });
    expect(findSubtitle().exists()).toBe(false);
  });

  it('renders the layover component', () => {
    expect(findLayover().exists()).toBe(true);
  });
});
