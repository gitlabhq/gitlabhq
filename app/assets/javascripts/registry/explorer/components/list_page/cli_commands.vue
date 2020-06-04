<script>
import { GlDropdown, GlFormGroup, GlFormInputGroup } from '@gitlab/ui';
import { mapGetters } from 'vuex';
import Tracking from '~/tracking';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import {
  QUICK_START,
  LOGIN_COMMAND_LABEL,
  COPY_LOGIN_TITLE,
  BUILD_COMMAND_LABEL,
  COPY_BUILD_TITLE,
  PUSH_COMMAND_LABEL,
  COPY_PUSH_TITLE,
} from '../../constants/index';

export default {
  components: {
    GlDropdown,
    GlFormGroup,
    GlFormInputGroup,
    ClipboardButton,
  },
  mixins: [Tracking.mixin({ label: 'quickstart_dropdown' })],
  i18n: {
    dropdownTitle: QUICK_START,
    loginCommandLabel: LOGIN_COMMAND_LABEL,
    copyLoginTitle: COPY_LOGIN_TITLE,
    buildCommandLabel: BUILD_COMMAND_LABEL,
    copyBuildTitle: COPY_BUILD_TITLE,
    pushCommandLabel: PUSH_COMMAND_LABEL,
    copyPushTitle: COPY_PUSH_TITLE,
  },
  computed: {
    ...mapGetters(['dockerBuildCommand', 'dockerPushCommand', 'dockerLoginCommand']),
  },
};
</script>
<template>
  <gl-dropdown
    :text="$options.i18n.dropdownTitle"
    variant="primary"
    size="sm"
    right
    @shown="track('click_dropdown')"
  >
    <!-- This li is used as a container since gl-dropdown produces a root ul, this mimics the functionality exposed by b-dropdown-form -->
    <li role="presentation" class="px-2 py-1 dropdown-menu-large">
      <form>
        <gl-form-group
          label-size="sm"
          label-for="docker-login-btn"
          :label="$options.i18n.loginCommandLabel"
        >
          <gl-form-input-group id="docker-login-btn" :value="dockerLoginCommand" readonly>
            <template #append>
              <clipboard-button
                class="border"
                :text="dockerLoginCommand"
                :title="$options.i18n.copyLoginTitle"
                @click.native="track('click_copy_login')"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>

        <gl-form-group
          label-size="sm"
          label-for="docker-build-btn"
          :label="$options.i18n.buildCommandLabel"
        >
          <gl-form-input-group id="docker-build-btn" :value="dockerBuildCommand" readonly>
            <template #append>
              <clipboard-button
                class="border"
                :text="dockerBuildCommand"
                :title="$options.i18n.copyBuildTitle"
                @click.native="track('click_copy_build')"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>

        <gl-form-group
          class="mb-0"
          label-size="sm"
          label-for="docker-push-btn"
          :label="$options.i18n.pushCommandLabel"
        >
          <gl-form-input-group id="docker-push-btn" :value="dockerPushCommand" readonly>
            <template #append>
              <clipboard-button
                class="border"
                :text="dockerPushCommand"
                :title="$options.i18n.copyPushTitle"
                @click.native="track('click_copy_push')"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </form>
    </li>
  </gl-dropdown>
</template>
