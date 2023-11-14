import { GlCollapsibleListbox, GlListboxItem } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import axios from '~/lib/utils/axios_utils';
import IssuableMoveDropdown from '~/sidebar/components/move/issuable_move_dropdown.vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

const mockProjects = [
  {
    id: 2,
    name_with_namespace: 'Gitlab Org / Gitlab Shell',
    full_path: 'gitlab-org/gitlab-shell',
  },
  {
    id: 3,
    name_with_namespace: 'Gnuwget / Wget2',
    full_path: 'gnuwget/wget2',
  },
  {
    id: 4,
    name_with_namespace: 'Commit451 / Lab Coat',
    full_path: 'Commit451/lab-coat',
  },
];

const mockProps = {
  projectsFetchPath: '/-/autocomplete/projects?project_id=1',
  dropdownButtonTitle: 'Move issuable',
  dropdownHeaderTitle: 'Move issuable',
  moveInProgress: false,
  disabled: false,
};

describe('IssuableMoveDropdown', () => {
  let mock;
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = mountExtended(IssuableMoveDropdown, { propsData: { ...mockProps, ...propsData } });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, mockProjects);
  });

  afterEach(() => {
    mock.restore();
  });

  const findDropdownButton = () => wrapper.findByTestId('dropdown-button');
  const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);
  const findDropdownMoveButton = () => wrapper.findByTestId('dropdown-move-button');
  const findDropdownItemsText = () =>
    wrapper.findAllComponents(GlListboxItem).wrappers.map((item) => item.text());

  it('renders a dropdown button with provided title and header', () => {
    createComponent();

    expect(findDropdownButton().text()).toBe(mockProps.dropdownButtonTitle);
    expect(findDropdown().props('headerText')).toBe(mockProps.dropdownHeaderTitle);
  });

  it('renders the dropdown button as disabled when disabled prop is true', () => {
    createComponent({ disabled: true });

    expect(findDropdownButton().props('disabled')).toBe(true);
  });

  it('triggers a project search when dropdown button is clicked', async () => {
    createComponent();

    await findDropdownButton().trigger('click');
    await waitForPromises();

    expect(mock.history.get).toHaveLength(1);

    expect(findDropdownItemsText()).toEqual([
      'Gitlab Org / Gitlab Shell',
      'Gnuwget / Wget2',
      'Commit451 / Lab Coat',
    ]);
  });

  it('shows "No matching results" when no projects are found', async () => {
    createComponent();

    mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, []);

    await findDropdown().vm.$emit('search', 'foobar');
    await waitForPromises();

    expect(findDropdown().text()).toContain('No matching results');
    expect(findDropdownItemsText()).toEqual([]);
  });

  it('shows "Failed to load projects" when request fails', async () => {
    createComponent();

    mock.onGet(mockProps.projectsFetchPath).networkError();

    await findDropdown().vm.$emit('search', 'foobar');
    await waitForPromises();

    expect(findDropdown().text()).toContain('Failed to load projects');
    expect(findDropdownItemsText()).toEqual([]);
  });

  it('disables the Move issuable button if no project is selected', async () => {
    createComponent();

    await findDropdownButton().trigger('click');
    await waitForPromises();

    expect(findDropdownMoveButton().props('disabled')).toBe(true);
  });

  it('shows search results when search is successful', async () => {
    createComponent();

    mock.onGet(mockProps.projectsFetchPath).reply(HTTP_STATUS_OK, [
      {
        id: 2,
        name_with_namespace: 'Gitlab Org / Gitlab Shell',
        full_path: 'gitlab-org/gitlab-shell',
      },
    ]);

    await findDropdown().vm.$emit('search', 'shell');
    await waitForPromises();

    expect(findDropdownItemsText()).toEqual(['Gitlab Org / Gitlab Shell']);
  });

  it('emits "move-issuable" event when Move issuable button is clicked', async () => {
    createComponent();

    await findDropdownButton().trigger('click');
    await waitForPromises();

    await wrapper.findAllComponents(GlListboxItem).wrappers[0].trigger('click');
    await findDropdownMoveButton().trigger('click');

    expect(wrapper.emitted('move-issuable')).toEqual([[mockProjects[0]]]);
  });

  it('disables the Move issuable button when moveInProgress prop is true', async () => {
    createComponent({ moveInProgress: true });

    await findDropdownButton().trigger('click');
    await waitForPromises();

    expect(findDropdownMoveButton().props('disabled')).toBe(true);
  });

  it('emits "dropdown-close" event when dropdown is hidden', async () => {
    createComponent();

    await findDropdownButton().trigger('click');
    await waitForPromises();

    await findDropdown().vm.$emit('hidden');

    expect(wrapper.emitted('dropdown-close')).toHaveLength(1);
  });
});
