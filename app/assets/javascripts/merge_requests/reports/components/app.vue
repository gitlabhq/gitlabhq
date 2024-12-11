<script>
import { GlIcon, GlBadge } from '@gitlab/ui';
import {
  BLOCKERS_ROUTE,
  CODE_QUALITY_ROUTE,
  LICENSE_COMPLIANCE_ROUTE,
  SECURITY_ROUTE,
} from '../constants';

export default {
  name: 'MergeRequestReportsApp',
  components: {
    GlIcon,
    GlBadge,
  },
  routeNames: {
    BLOCKERS_ROUTE,
    CODE_QUALITY_ROUTE,
    SECURITY_ROUTE,
    LICENSE_COMPLIANCE_ROUTE,
  },
  data() {
    return {
      blockersCounter: 2,
    };
  },
};
</script>

<template>
  <div class="gl-grid gl-grid-cols-[1fr] gl-gap-5 md:gl-min-h-31 md:gl-grid-cols-[200px,1fr]">
    <h2 class="gl-sr-only">{{ s__('MrReports|Reports') }}</h2>
    <aside
      class="gl-border-b gl-border-default gl-pb-3 gl-pt-5 md:gl-border-r md:gl-border-0 md:gl-pr-5"
    >
      <nav>
        <router-link
          :to="{ name: $options.routeNames.BLOCKERS_ROUTE }"
          active-class="gl-font-bold gl-bg-gray-50"
          exact
          class="gl-flex gl-items-center gl-rounded-base gl-p-2 gl-text-default hover:gl-bg-gray-50 hover:gl-text-default hover:gl-no-underline"
        >
          <span class="gl-mr-3 gl-flex gl-rounded-full gl-bg-red-100 gl-p-2">
            <gl-icon class="gl-rounded-full gl-bg-white gl-text-red-500" name="status-failed" />
          </span>
          {{ s__('MrReports|Blockers') }}
          <gl-badge class="gl-ml-auto gl-mr-2" variant="neutral"
            ><span data-testid="blockers-counter" class="gl-font-bold">{{
              blockersCounter
            }}</span></gl-badge
          >
        </router-link>
        <div class="gl-border-t gl-mt-2 gl-border-default gl-pt-1">
          <h3
            class="gl-heading-6 gl-mb-0 gl-py-3 gl-pl-3 gl-text-sm gl-font-[700] gl-leading-normal"
          >
            {{ s__('MrReports|All reports') }}
          </h3>
          <ul class="gl-m-0 gl-list-none gl-p-0">
            <li class="gl-my-1">
              <router-link
                :to="{ name: $options.routeNames.CODE_QUALITY_ROUTE }"
                active-class="gl-font-bold gl-bg-gray-50"
                class="gl-flex gl-items-center gl-rounded-base gl-p-2 gl-text-default hover:gl-bg-gray-50 hover:gl-text-default hover:gl-no-underline"
              >
                <span class="gl-mr-3 gl-flex gl-p-2">
                  <gl-icon
                    class="gl-rounded-full gl-bg-white gl-text-orange-500"
                    name="status-alert"
                  />
                </span>
                {{ s__('MrReports|Code quality') }}
              </router-link>
            </li>
            <li class="gl-my-1">
              <router-link
                :to="{ name: $options.routeNames.SECURITY_ROUTE }"
                active-class="gl-font-bold gl-bg-gray-50"
                class="gl-flex gl-items-center gl-rounded-base gl-p-2 gl-text-default hover:gl-bg-gray-50 hover:gl-text-default hover:gl-no-underline"
              >
                <span class="gl-mr-3 gl-flex gl-p-2">
                  <gl-icon
                    class="gl-rounded-full gl-bg-white gl-text-red-500"
                    name="status-failed"
                  />
                </span>
                {{ s__('MrReports|Security') }}
              </router-link>
            </li>
            <li class="gl-my-1">
              <router-link
                :to="{ name: $options.routeNames.LICENSE_COMPLIANCE_ROUTE }"
                active-class="gl-font-bold gl-bg-gray-50"
                class="gl-flex gl-items-center gl-rounded-base gl-p-2 gl-text-default hover:gl-bg-gray-50 hover:gl-text-default hover:gl-no-underline"
              >
                <span class="gl-mr-3 gl-flex gl-p-2">
                  <gl-icon
                    class="gl-rounded-full gl-bg-white gl-text-red-500"
                    name="status-failed"
                  />
                </span>
                {{ s__('MrReports|License Compliance') }}
              </router-link>
            </li>
          </ul>
        </div>
      </nav>
    </aside>
    <section class="md:gl-pt-5">
      <router-view />
    </section>
  </div>
</template>
