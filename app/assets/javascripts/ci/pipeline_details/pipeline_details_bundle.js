import VueRouter from 'vue-router';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { pipelineTabName } from './constants';
import { createPipelineHeaderApp } from './pipeline_header';
import { apolloProvider } from './pipeline_shared_client';

const SELECTORS = {
  PIPELINE_HEADER: '#js-pipeline-header',
  PIPELINE_TABS: '#js-pipeline-tabs',
};

export default async function initPipelineDetailsBundle() {
  const headerSelector = SELECTORS.PIPELINE_HEADER;

  const headerEl = document.querySelector(headerSelector);

  if (headerEl) {
    const { dataset: headerDataset } = headerEl;

    try {
      createPipelineHeaderApp(headerSelector, apolloProvider, headerDataset.graphqlResourceEtag);
    } catch {
      createAlert({
        message: __('An error occurred while loading a section of this page.'),
      });
    }
  }

  const tabsEl = document.querySelector(SELECTORS.PIPELINE_TABS);

  if (tabsEl) {
    let validityChecksEnabled;

    const { dataset } = tabsEl;
    const dismissalDescriptions = JSON.parse(dataset.dismissalDescriptions || '{}');
    const { createAppOptions } = await import('ee_else_ce/ci/pipeline_details/pipeline_tabs');
    const { createPipelineTabs } = await import('./pipeline_tabs');
    const { routes } = await import('ee_else_ce/ci/pipeline_details/routes');

    try {
      validityChecksEnabled = JSON.parse(dataset.validityChecksEnabled);
    } catch {
      validityChecksEnabled = 'false';
    }

    const securityRoute = routes.find((route) => route.path === '/security');
    if (securityRoute) {
      securityRoute.props = { dismissalDescriptions, validityChecksEnabled };
    }

    const router = new VueRouter({
      mode: 'history',
      base: dataset.pipelinePath,
      routes,
    });

    // We handle the shortcut `pipelines/latest` by forwarding the user to the pipeline graph
    // tab and changing the route to the correct `pipelines/:id`
    if (window.location.pathname.endsWith('latest')) {
      router.replace({ name: pipelineTabName });
    }

    try {
      const appOptions = createAppOptions(SELECTORS.PIPELINE_TABS, apolloProvider, router);
      createPipelineTabs(appOptions);
    } catch {
      createAlert({
        message: __('An error occurred while loading a section of this page.'),
      });
    }
  }
}
