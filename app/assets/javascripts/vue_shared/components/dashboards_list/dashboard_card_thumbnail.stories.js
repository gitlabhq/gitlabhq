import DashboardCardThumbnail from './dashboard_card_thumbnail.vue';
import { configToPreviewPieces } from './dashboard_preview_layout';

export default {
  component: DashboardCardThumbnail,
  title: 'vue_shared/components/dashboards_list/dashboard_card_thumbnail',
};

const Template = (args, { argTypes }) => ({
  components: { DashboardCardThumbnail },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-rounded-lg gl-border gl-border-default" style="max-width: 320px">
      <dashboard-card-thumbnail :seed-key="seedKey" :pieces="pieces" />
    </div>
  `,
});

export const Seeded = Template.bind({});
Seeded.args = {
  seedKey: 'gid://gitlab/Analytics::CustomDashboard/1',
  pieces: null,
};

// A realistic dashboard config (shaped like the Duo and SDLC trends system
// dashboard) whose panels the thumbnail mimics: a stat header row, then the
// next panels in reading order.
const MIMIC_CONFIG = {
  panels: [
    {
      title: 'GitLab Duo users',
      visualization: { type: 'SingleStat', data: {}, options: {} },
      gridAttributes: { yPos: 0, xPos: 0, width: 4, height: 1 },
    },
    {
      title: 'GitLab Duo power users',
      visualization: { type: 'SingleStat', data: {}, options: {} },
      gridAttributes: { yPos: 0, xPos: 4, width: 4, height: 1 },
    },
    {
      title: 'GitLab Duo agent/flow users',
      visualization: { type: 'SingleStat', data: {}, options: {} },
      gridAttributes: { yPos: 0, xPos: 8, width: 4, height: 1 },
    },
    {
      title: 'GitLab Duo Agent Chat sessions',
      visualization: { type: 'SingleStat', data: {}, options: {} },
      gridAttributes: { yPos: 1, xPos: 0, width: 4, height: 1 },
    },
    {
      title: 'Flow usage',
      visualization: { type: 'DataTable', data: {}, options: {} },
      gridAttributes: { yPos: 2, xPos: 0, width: 8, height: 4 },
    },
    {
      title: 'Pipelines over time',
      visualization: { type: 'LineChart', data: {}, options: {} },
      gridAttributes: { yPos: 2, xPos: 8, width: 4, height: 4 },
    },
  ],
};

export const MimickedFromConfig = Template.bind({});
MimickedFromConfig.args = {
  seedKey: 'duo_and_sdlc_trends',
  pieces: configToPreviewPieces(MIMIC_CONFIG),
};

// A spread of seed keys so designers can eyeball the generated variety:
// every template and accent shows up at least once.
const GALLERY_SEED_KEYS = [
  'dap_impact',
  'duo_and_sdlc_trends',
  'gid://gitlab/Analytics::CustomDashboard/1',
  'issues_analytics',
  'sprint-health',
  'security-dashboard',
  'deployment-frequency',
  'vulnerabilities',
];

const GalleryTemplate = (args, { argTypes }) => ({
  components: { DashboardCardThumbnail },
  props: Object.keys(argTypes),
  template: `
    <div class="gl-grid gl-grid-cols-4 gl-gap-5">
      <div
        v-for="seedKey in seedKeys"
        :key="seedKey"
        class="gl-rounded-lg gl-border gl-border-default"
      >
        <dashboard-card-thumbnail :seed-key="seedKey" />
        <p class="gl-m-0 gl-truncate gl-p-3 gl-text-sm gl-text-subtle">{{ seedKey }}</p>
      </div>
    </div>
  `,
});

export const Gallery = GalleryTemplate.bind({});
Gallery.args = { seedKeys: GALLERY_SEED_KEYS };
