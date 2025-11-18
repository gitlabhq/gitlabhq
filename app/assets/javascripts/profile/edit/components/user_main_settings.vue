<script>
import { GlFormGroup, GlFormInput, GlFormTextarea, GlFormCheckbox, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { sanitize } from '~/lib/dompurify';
import UserEmailSetting from './user_email_setting.vue';

export default {
  components: {
    GlLink,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlFormCheckbox,
    UserEmailSetting,
  },
  i18n: {
    fullName: s__('Profiles|Full name'),
    fullNameDescription: s__('Profiles|Enter your name, so people you know can recognize you.'),
    fullNameSafeDescription: sanitize(s__('Profiles|No "&lt;" or "&gt;" characters, please.'), {
      ALLOWED_TAGS: [],
    }),
    fullNameRequired: s__(
      'Profiles|Using emoji in names seems fun, but please try to set a status message instead',
    ),
    userId: s__('Profiles|User ID'),
    pronouns: s__('Profiles|Pronouns'),
    pronounsDescription: s__(
      'Profiles|Enter your pronouns to let people know how to refer to you.',
    ),
    pronunciation: s__('Profiles|Pronunciation'),
    pronunciationDescription: s__(
      'Profiles|Enter how your name is pronounced to help people address you correctly.',
    ),
    websiteUrl: s__('Profiles|Website URL'),
    websiteUrlPlaceholder: s__('Profiles|https://website.com'),
    location: s__('Profiles|Location'),
    locationPlaceholder: s__('Profiles|City, country'),
    jobTitle: s__('Profiles|Job title'),
    organization: s__('Profiles|Organization'),
    organizationDescription: s__('Profiles|Who you represent or work for.'),
    bio: s__('Profiles|Bio'),
    bioDescription: s__('Profiles|Tell us about yourself in fewer than 250 characters.'),
    privateProfile: s__('Profiles|Private profile'),
    privateProfileLabel: s__(
      "Profiles|Don't display activity-related personal information on your profile.",
    ),
    privateProfileLink: s__('Profiles|what information is hidden?'),
    privateContributions: s__('Profiles|Private contributions'),
    privateContributionsLabel: s__('Profiles|Include private contributions on your profile'),
    privateContributionsDescription: s__(
      'Profiles|Choose to show contributions of private projects on your public profile without any project, repository or organization information.',
    ),
    achievements: s__('Profiles|Achievements'),
    achievementsLabel: s__('Profiles|Display achievements on your profile'),
  },
  props: {
    userSettings: {
      type: Object,
      required: true,
    },
    emailHelpText: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    form: {
      get() {
        return this.userSettings;
      },
      set(value) {
        this.$emit('change', value);
      },
    },
    nameState() {
      return this.form.name.trim().length > 0;
    },
    fullNameDescription() {
      return this.nameState
        ? `${this.$options.i18n.fullNameDescription} ${this.$options.i18n.fullNameSafeDescription}`
        : '';
    },
  },
  methods: {
    handleEmailSettingsChange(emailSettings) {
      this.$emit('change', {
        ...this.userSettings,
        ...emailSettings,
      });
    },
  },
  privatePageLink: helpPagePath('/user/profile/_index.md', {
    anchor: 'make-your-user-profile-page-private',
  }),
};
</script>

<template>
  <div>
    <gl-form-group
      :label="$options.i18n.fullName"
      :description="fullNameDescription"
      :state="nameState"
      :invalid-feedback="$options.i18n.fullNameRequired"
      data-testid="full-name-group"
    >
      <gl-form-input v-model="form.name" width="lg" required :state="nameState" />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.userId" data-testid="user-id-group">
      <gl-form-input v-model="form.id" width="lg" readonly />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.pronouns"
      :description="$options.i18n.pronounsDescription"
      data-testid="pronouns-group"
    >
      <gl-form-input v-model="form.pronouns" width="lg" />
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.pronunciation"
      :description="$options.i18n.pronunciationDescription"
      data-testid="pronunciation-group"
    >
      <gl-form-input v-model="form.pronunciation" width="lg" />
    </gl-form-group>
    <user-email-setting
      :user-email-settings="form"
      :email-help-text="emailHelpText"
      @change="handleEmailSettingsChange"
    />
    <gl-form-group :label="$options.i18n.websiteUrl" data-testid="website-url-group">
      <gl-form-input
        v-model="form.websiteUrl"
        width="lg"
        :placeholder="$options.i18n.websiteUrlPlaceholder"
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.location" data-testid="location-group">
      <gl-form-input
        v-model="form.location"
        width="lg"
        :placeholder="$options.i18n.locationPlaceholder"
      />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.jobTitle" data-testid="job-title-group">
      <gl-form-input v-model="form.jobTitle" width="lg" />
    </gl-form-group>
    <gl-form-group :label="$options.i18n.organization" data-testid="organization-group">
      <gl-form-input v-model="form.organization" width="lg" />
      <template #description>{{ $options.i18n.organizationDescription }}</template>
    </gl-form-group>
    <gl-form-group
      :label="$options.i18n.bio"
      :description="$options.i18n.bioDescription"
      data-testid="bio-group"
      class="gl-mb-6 gl-max-w-80"
    >
      <gl-form-textarea v-model="form.bio" rows="4" maxlength="250" />
    </gl-form-group>
    <div class="gl-border-t gl-pt-6">
      <gl-form-group :label="$options.i18n.privateProfile" data-testid="private-profile-group">
        <gl-form-checkbox v-model="form.privateProfile" data-testid="private-profile-checkbox">
          {{ $options.i18n.privateProfileLabel }}
          <gl-link :href="$options.privatePageLink" data-testid="private-profile-link">{{
            $options.i18n.privateProfileLink
          }}</gl-link>
        </gl-form-checkbox>
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.privateContributions"
        data-testid="private-contributions-group"
      >
        <gl-form-checkbox v-model="form.includePrivateContributions">
          {{ $options.i18n.privateContributionsLabel }}
          <template #help>
            {{ $options.i18n.privateContributionsDescription }}
          </template>
        </gl-form-checkbox>
      </gl-form-group>
      <gl-form-group
        :label="$options.i18n.achievements"
        class="gl-mb-0"
        data-testid="achievements-group"
      >
        <gl-form-checkbox v-model="form.achievementsEnabled">
          {{ $options.i18n.achievementsLabel }}
        </gl-form-checkbox>
      </gl-form-group>
    </div>
  </div>
</template>
