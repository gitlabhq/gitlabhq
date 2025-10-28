import { GlFormCheckbox, GlFormInput, GlFormTextarea, GlFormGroup, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import UserMainSettings from '~/profile/edit/components/user_main_settings.vue';
import UserEmailSetting from '~/profile/edit/components/user_email_setting.vue';

jest.mock('~/helpers/help_page_helper');

const mockPrivatePageLink = '/user/profile/_index.md#make-your-user-profile-page-private';

const i18n = {
  name: 'Name',
  nameRequired: 'Using emoji in names seems fun, but please try to set a status message instead',
  nameDescription: 'Enter your name',
  userId: 'User ID',
  pronouns: 'Pronouns',
  pronunciation: 'Name pronunciation',
  websiteUrl: 'Website URL',
  location: 'Location',
  jobTitle: 'Job title',
  organization: 'Organization',
  bio: 'Bio',
  privateProfile: 'Private profile',
  privateProfileLabel: 'Make profile private',
  privateProfileLink: 'what information is hidden?',
  privateContributions: 'Private contributions',
  privateContributionsLabel: 'Include private contributions',
  achievements: 'Achievements',
  achievementsLabel: 'Show achievements',
  fullNameDescription: 'Enter your name, so people you know can recognize you.',
  fullNameSafeDescription: 'No "&lt;" or "&gt;" characters, please.',
};

describe('MainSetting', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(UserMainSettings, {
      propsData: {
        userSettings: {
          id: '123',
          name: '',
          ...props,
        },
      },
      provide: {
        i18n,
      },
      stubs: {
        GlFormGroup: stubComponent(GlFormGroup, {
          props: ['state', 'invalidFeedback', 'description'],
        }),
        GlLink: stubComponent(GlLink, {
          template: `<a :href="mockPrivatePageLink" data-testid="private-profile-link"><slot /></a>`,
          setup() {
            return { mockPrivatePageLink };
          },
        }),
      },
    });
  };

  describe('user interactions', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      testId                           | name
      ${'full-name-group'}             | ${'Full Name'}
      ${'user-id-group'}               | ${'User ID'}
      ${'pronouns-group'}              | ${'Pronouns'}
      ${'pronunciation-group'}         | ${'Pronunciation'}
      ${'website-url-group'}           | ${'Website URL'}
      ${'location-group'}              | ${'Location'}
      ${'job-title-group'}             | ${'Job Title'}
      ${'organization-group'}          | ${'Organization'}
      ${'bio-group'}                   | ${'Bio'}
      ${'private-profile-group'}       | ${'Private Profile'}
      ${'private-contributions-group'} | ${'Private Contributions'}
      ${'achievements-group'}          | ${'Achievements'}
    `('displays the $name field', ({ testId }) => {
      expect(wrapper.findByTestId(testId).exists()).toBe(true);
    });

    it('displays help link for private profile with correct text', () => {
      const link = wrapper.findByTestId('private-profile-link');
      expect(link.text()).toBe(i18n.privateProfileLink);
      expect(link.attributes('href')).toBe(mockPrivatePageLink);
    });
  });

  describe('form validation', () => {
    it('shows error message when name is empty', () => {
      createComponent({ name: '' });

      const nameGroup = wrapper.findByTestId('full-name-group');
      expect(nameGroup.props('state')).toBe(false);
      expect(nameGroup.props('invalidFeedback')).toBe(i18n.nameRequired);
    });

    it('shows no error when name is provided', () => {
      createComponent({ name: 'John Doe' });

      const nameGroup = wrapper.findByTestId('full-name-group');
      const description = `${i18n.fullNameDescription} ${i18n.fullNameSafeDescription}`;
      expect(nameGroup.props('state')).toBe(true);
      expect(nameGroup.props('description')).toBe(description);
    });
  });

  describe('form interaction', () => {
    beforeEach(() => {
      createComponent();
    });

    it.each`
      testId                   | inputValue               | formProperty       | componentType
      ${'full-name-group'}     | ${'John Doe'}            | ${'name'}          | ${GlFormInput}
      ${'pronouns-group'}      | ${'they/them'}           | ${'pronouns'}      | ${GlFormInput}
      ${'pronunciation-group'} | ${'jawn-doe'}            | ${'pronunciation'} | ${GlFormInput}
      ${'website-url-group'}   | ${'https://example.com'} | ${'websiteUrl'}    | ${GlFormInput}
      ${'location-group'}      | ${'San Francisco, CA'}   | ${'location'}      | ${GlFormInput}
      ${'job-title-group'}     | ${'Software Engineer'}   | ${'jobTitle'}      | ${GlFormInput}
      ${'organization-group'}  | ${'GitLab'}              | ${'organization'}  | ${GlFormInput}
      ${'bio-group'}           | ${'This is my bio'}      | ${'bio'}           | ${GlFormTextarea}
    `(
      'updates $formProperty field when user types',
      async ({ testId, inputValue, formProperty, componentType }) => {
        const input = wrapper.findByTestId(testId).findComponent(componentType);
        await input.vm.$emit('input', inputValue);
        expect(wrapper.vm.form[formProperty]).toBe(inputValue);

        await wrapper.vm.$emit('change', wrapper.vm.form);
        expect(wrapper.emitted()).toHaveProperty('change');
        expect(wrapper.emitted('change')[0][0]).toEqual(
          expect.objectContaining({
            [formProperty]: inputValue,
          }),
        );
      },
    );

    it.each`
      testId                           | formProperty
      ${'private-profile-group'}       | ${'privateProfile'}
      ${'private-contributions-group'} | ${'includePrivateContributions'}
      ${'achievements-group'}          | ${'achievementsEnabled'}
    `('toggles $formProperty checkbox', async ({ testId, formProperty }) => {
      const checkbox = wrapper.findByTestId(testId).findComponent(GlFormCheckbox);
      await checkbox.vm.$emit('input', true);
      expect(wrapper.vm.form[formProperty]).toBe(true);

      await wrapper.vm.$emit('change', wrapper.vm.form);
      expect(wrapper.emitted()).toHaveProperty('change');
      expect(wrapper.emitted('change')[0][0]).toEqual(
        expect.objectContaining({
          [formProperty]: true,
        }),
      );
    });
  });

  describe('readonly fields', () => {
    beforeEach(() => {
      createComponent();
    });

    it('prevents user from editing user ID', () => {
      const userIdInput = wrapper.findByTestId('user-id-group').findComponent(GlFormInput);
      expect(userIdInput.props('readonly')).toBe(true);
    });
  });

  describe('email settings integration', () => {
    it('includes email component', () => {
      createComponent();

      expect(wrapper.findComponent(UserEmailSetting).exists()).toBe(true);
    });
  });
});
