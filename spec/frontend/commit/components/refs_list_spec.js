import { GlCollapse, GlButton, GlBadge, GlLoadingIcon, GlSkeletonLoader } from '@gitlab/ui';
import RefsList from '~/projects/commit_box/info/components/refs_list.vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  CONTAINING_COMMIT,
  FETCH_CONTAINING_REFS_EVENT,
} from '~/projects/commit_box/info/constants';
import { refsListPropsMock, containingBranchesMock } from '../mock_data';

describe('Commit references component', () => {
  let wrapper;
  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(RefsList, {
      propsData: {
        ...refsListPropsMock,
        ...props,
      },
    });
  };

  const findTitle = () => wrapper.findByTestId('title');
  const findCollapseButton = () => wrapper.findComponent(GlButton);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTippingRefs = () => wrapper.findAllComponents(GlBadge);
  const findContainingRefs = () => wrapper.findComponent(GlCollapse);
  const findEmptyMessage = () => wrapper.findByText('No related branches found');
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  beforeEach(() => {
    createComponent();
  });

  it('renders a loading icon when loading', () => {
    createComponent({ isLoading: true });
    expect(findLoadingIcon().exists()).toBe(true);
  });

  it('renders the namespace passed', () => {
    expect(findTitle().text()).toEqual(refsListPropsMock.namespace);
  });

  it('renders list of tipping branches or tags', () => {
    expect(findTippingRefs()).toHaveLength(refsListPropsMock.tippingRefs.length);
  });

  it('does not render collapse with containing branches ot tags when there is no data', () => {
    createComponent({ hasContainingRefs: false });
    expect(findCollapseButton().exists()).toBe(false);
  });

  it('renders collapse component if commit has containing branches', () => {
    expect(findCollapseButton().text()).toContain(CONTAINING_COMMIT);
  });

  it('emits event when collapse button is clicked', () => {
    findCollapseButton().vm.$emit('click');
    expect(wrapper.emitted()[FETCH_CONTAINING_REFS_EVENT]).toHaveLength(1);
  });

  it('renders the list of containing branches or tags when collapse is expanded', () => {
    createComponent({ containingRefs: containingBranchesMock });
    const containingRefsList = findContainingRefs();
    expect(containingRefsList.findAllComponents(GlBadge)).toHaveLength(
      containingBranchesMock.length,
    );
  });

  it('renders links to refs', () => {
    const index = 0;
    const refBadge = findTippingRefs().at(index);
    const refUrl = `${refsListPropsMock.urlPart}${refsListPropsMock.tippingRefs[index]}?ref_type=${refsListPropsMock.refType}`;
    expect(refBadge.attributes('href')).toBe(refUrl);
  });

  it('does not render list of tipping branches or tags if there is no data', () => {
    createComponent({ tippingRefs: [] });
    expect(findTippingRefs().exists()).toBe(false);
  });

  it('renders an empty message when there is no tipping and containing refs', () => {
    createComponent({ tippingRefs: [] });
    expect(findEmptyMessage().exists()).toBe(true);
  });

  it('renders skeleton loader when isLoading prop has true value', () => {
    createComponent({ isLoading: true, containingRefs: [] });
    expect(findSkeletonLoader().exists()).toBe(true);
  });
});
