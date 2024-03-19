import { GlCard, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AssociationCountCard from '~/organizations/show/components/association_count_card.vue';

describe('AssociationCountCard', () => {
  let wrapper;

  const defaultPropsData = {
    title: 'Groups',
    iconName: 'group',
    count: '1000+',
    linkHref: '/-/organizations/default/groups_and_projects?display=groups',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(AssociationCountCard, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  const findCard = () => wrapper.findComponent(GlCard);
  const findLink = () => findCard().findComponent(GlLink);

  it('renders card with title, link and count', () => {
    createComponent();

    const card = findCard();
    const link = findLink();

    expect(card.text()).toContain(defaultPropsData.title);
    expect(card.text()).toContain('1000+');
    expect(link.text()).toBe('View all');
    expect(link.attributes('href')).toBe(defaultPropsData.linkHref);
  });

  describe('when `linkText` prop is set', () => {
    const linkText = 'Manage';
    beforeEach(() => {
      createComponent({
        propsData: { linkText },
      });
    });

    it('sets link text', () => {
      expect(findLink().text()).toBe(linkText);
    });
  });
});
