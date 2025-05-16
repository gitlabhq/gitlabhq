import { GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AccessSummary from '~/admin/users/components/user_type/access_summary.vue';

describe('AccessSummary component', () => {
  let wrapper;

  const createWrapper = (scopedSlots) => {
    wrapper = shallowMountExtended(AccessSummary, {
      scopedSlots,
    });
  };

  const findSections = () => wrapper.findAll('section');
  const findAdminSection = () => findSections().at(0);
  const findGroupSection = () => findSections().at(1);
  const findSettingsSection = () => findSections().at(2);

  it('shows 3 sections', () => {
    createWrapper();

    expect(findSections()).toHaveLength(3);
  });

  describe.each`
    section       | icon          | text                             | findSection
    ${'admin'}    | ${'admin'}    | ${'Admin area'}                  | ${findAdminSection}
    ${'group'}    | ${'group'}    | ${'Groups and projects'}         | ${findGroupSection}
    ${'settings'} | ${'settings'} | ${'Groups and project settings'} | ${findSettingsSection}
  `('$section section', ({ section, icon, text, findSection }) => {
    const findContent = () => findSection().find('div');
    const findListContent = () => findSection().find('ul');

    it('shows section icon', () => {
      createWrapper();

      expect(findSection().findComponent(GlIcon).props('name')).toBe(icon);
    });

    it('shows section text', () => {
      createWrapper();

      expect(findSection().text()).toBe(text);
    });

    describe(`when there is ${section} content slot content`, () => {
      beforeEach(() => {
        createWrapper({ [`${section}-content`]: '<span>slot content</span>' });
      });

      it(`shows ${section} slot content`, () => {
        expect(findContent().element.innerHTML).toBe('<span>slot content</span>');
      });

      it(`does not show ${section} list slot content`, () => {
        expect(findListContent().exists()).toBe(false);
      });
    });

    describe(`when there is ${section} list slot content`, () => {
      beforeEach(() => {
        createWrapper({ [`${section}-list`]: '<li>list slot content</li>' });
      });

      it(`does not show ${section} slot content`, () => {
        expect(findContent().exists()).toBe(false);
      });

      it(`shows ${section} list slot content`, () => {
        expect(findListContent().element.innerHTML).toBe('<li>list slot content</li>');
      });
    });

    describe(`when there is ${section} slot content and ${section} list slot content`, () => {
      beforeEach(() => {
        createWrapper({
          [`${section}-content`]: '<span>slot content</span>',
          [`${section}-list`]: '<li>list slot content</li>',
        });
      });

      it(`shows ${section} slot content`, () => {
        expect(findContent().element.innerHTML).toBe('<span>slot content</span>');
      });

      it(`shows ${section} list slot content`, () => {
        expect(findListContent().element.innerHTML).toBe('<li>list slot content</li>');
      });
    });
  });
});
