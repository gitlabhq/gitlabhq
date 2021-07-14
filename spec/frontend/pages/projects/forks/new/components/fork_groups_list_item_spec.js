import { GlBadge, GlButton, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ForkGroupsListItem from '~/pages/projects/forks/new/components/fork_groups_list_item.vue';

describe('Fork groups list item component', () => {
  let wrapper;

  const DEFAULT_GROUP_DATA = {
    id: 22,
    name: 'Gitlab Org',
    description: 'Ad et ipsam earum id aut nobis.',
    visibility: 'public',
    full_name: 'Gitlab Org',
    created_at: '2020-06-22T03:32:05.664Z',
    updated_at: '2020-06-22T03:32:05.664Z',
    avatar_url: null,
    fork_path: '/twitter/typeahead-js/-/forks?namespace_key=22',
    forked_project_path: null,
    permission: 'Owner',
    relative_path: '/gitlab-org',
    markdown_description:
      '<p data-sourcepos="1:1-1:31" dir="auto">Ad et ipsam earum id aut nobis.</p>',
    can_create_project: true,
    marked_for_deletion: false,
  };

  const DUMMY_PATH = '/dummy/path';

  const createWrapper = (propsData) => {
    wrapper = shallowMount(ForkGroupsListItem, {
      propsData: {
        ...propsData,
      },
    });
  };

  it('renders pending deletion badge if applicable', () => {
    createWrapper({ group: { ...DEFAULT_GROUP_DATA, marked_for_deletion: true } });

    expect(wrapper.find(GlBadge).text()).toBe('pending deletion');
  });

  it('renders go to fork button if has forked project', () => {
    createWrapper({ group: { ...DEFAULT_GROUP_DATA, forked_project_path: DUMMY_PATH } });

    expect(wrapper.find(GlButton).text()).toBe('Go to fork');
    expect(wrapper.find(GlButton).attributes().href).toBe(DUMMY_PATH);
  });

  it('renders select button if has no forked project', () => {
    createWrapper({
      group: { ...DEFAULT_GROUP_DATA, forked_project_path: null, fork_path: DUMMY_PATH },
    });

    expect(wrapper.find(GlButton).text()).toBe('Select');
    expect(wrapper.find('form').attributes().action).toBe(DUMMY_PATH);
  });

  it('renders link to current group', () => {
    const DUMMY_FULL_NAME = 'dummy';
    createWrapper({
      group: { ...DEFAULT_GROUP_DATA, relative_path: DUMMY_PATH, full_name: DUMMY_FULL_NAME },
    });

    expect(
      wrapper
        .findAll(GlLink)
        .filter((w) => w.text() === DUMMY_FULL_NAME)
        .at(0)
        .attributes().href,
    ).toBe(DUMMY_PATH);
  });
});
