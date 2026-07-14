import { GlAlert, GlBadge, GlButton, GlLink } from '@gitlab/ui';
import DetailLayout from './detail_layout.vue';

const Template = (args, { argTypes }) => ({
  components: { DetailLayout },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
      <p>Detail layout default slot.</p>
    </detail-layout>
  `,
});

export const Default = Template.bind({});
Default.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const WithSlots = (args, { argTypes }) => ({
  components: { DetailLayout, GlButton, GlLink },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
      <template #heading>
        Custom <i>Heading</i> with Markup
      </template>
      <template #description>
        Custom <i>description</i> information with Markup.
        <gl-link>Learn more.</gl-link>
      </template>
      <template #actions>
        <gl-button variant="confirm">Primary action</gl-button>
        <gl-button>Secondary action</gl-button>
      </template>
      <template #sidebar>
        <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 1024px;">
          Detail layout sidebar slot.
        </div>
      </template>
       <template #widgets>
        <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 512px;">
          Detail layout widgets slot.
        </div>
      </template>
      <template #activity>
        <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 512px;">
          Detail layout activity slot.
        </div>
      </template>
      <div class="gl-w-full gl-bg-strong gl-p-5" style="height: 1024px;">
        Detail layout default slot.
      </div>
    </detail-layout>
  `,
});
WithSlots.args = {};

export const WithStickyHeader = (args, { argTypes }) => ({
  components: { DetailLayout, GlAlert, GlBadge },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
      <template #heading>
        Header
      </template>
      <template #description>
        Description
      </template>
      <template #sticky-header>
        <h2 class="gl-heading-scale-400 gl-m-0">Sticky Header</h2>
        <div class="gl-text-sm gl-text-subtle gl-flex gl-gap-2 gl-items-center">
          <gl-badge variant="success">Open</gl-badge>
          Meta information
        </div>
      </template>
      <p>Esse commodo non aliquip cupidatat ut incididunt reprehenderit proident voluptate. Exercitation enim sunt occaecat Lorem tempor enim nulla ut laborum magna laborum. Consectetur cillum cupidatat ad dolore Lorem ipsum excepteur aliquip do pariatur do velit nulla reprehenderit. Esse sunt labore laborum laborum fugiat duis enim cillum occaecat. Aute esse in aliqua duis deserunt nisi tempor consequat incididunt sit. Est ut officia occaecat eu est do mollit tempor.

Incididunt ipsum esse et exercitation eiusmod consectetur nostrud non commodo aliqua velit reprehenderit quis enim. Tempor labore dolor ut qui. Consectetur exercitation duis exercitation cupidatat adipisicing do culpa ipsum commodo proident deserunt incididunt. Mollit cupidatat id ut adipisicing occaecat est sint commodo minim minim amet sunt minim aliquip veniam. Non quis minim sunt amet minim laborum cupidatat consectetur anim. Veniam cillum et fugiat voluptate sunt. Magna laborum ad aliquip deserunt ex.

Fugiat proident culpa exercitation occaecat cupidatat exercitation do voluptate esse laboris. Est qui ex nostrud pariatur. Quis culpa laborum amet. Ullamco labore excepteur enim culpa do minim consequat deserunt.

Incididunt magna eu aute aute sunt dolore mollit nulla proident laborum adipisicing consectetur velit ullamco. Irure ex irure aute enim reprehenderit aliqua mollit. Pariatur ullamco dolor minim fugiat. Amet excepteur laborum dolore enim incididunt culpa aliquip enim ut esse. Sunt et eu occaecat esse excepteur veniam eiusmod veniam labore. Elit exercitation et ex ea deserunt anim elit consectetur aliquip do qui voluptate est consectetur occaecat. Exercitation minim ipsum eiusmod id amet. Dolor amet laboris pariatur sint anim ea ex aliqua ea deserunt reprehenderit.

Est esse ullamco ut adipisicing eiusmod dolore anim culpa. Amet aute nostrud et dolor consequat tempor. Magna aliqua dolore sunt veniam veniam in Lorem ea pariatur. Sunt magna aliquip nostrud aute culpa sit ut duis ad do proident ea labore duis.

Pariatur nulla reprehenderit quis voluptate magna dolor nisi ad. Fugiat dolor exercitation eu anim consequat minim voluptate sunt irure. Magna voluptate labore in. Enim culpa exercitation do culpa.

Dolore sint veniam sunt tempor ea officia culpa ipsum magna mollit laboris quis. Velit nostrud irure non tempor dolore minim veniam. Lorem pariatur excepteur ut laboris. Occaecat consequat ut incididunt consequat nulla quis incididunt minim velit. Magna deserunt ut reprehenderit culpa irure elit consequat eu occaecat commodo deserunt voluptate sit. Proident dolore eu deserunt in. Duis non commodo officia laborum elit sint quis consequat.

Sit quis enim sunt. Nulla ea sint nisi ea sit esse dolor laborum Lorem amet officia nulla sit minim. Consectetur commodo eu officia tempor proident magna. In minim in ullamco fugiat cupidatat aute dolor irure dolor elit sint. Commodo cupidatat velit consectetur consectetur nostrud excepteur reprehenderit sit ex est nostrud nulla nisi. Proident excepteur cupidatat sunt nostrud laborum aliqua.

Non velit anim anim exercitation nisi ad. Mollit mollit velit irure irure ut. Anim ipsum tempor cillum culpa tempor. Ullamco proident cillum cillum officia. Magna irure ad nisi tempor consectetur deserunt et est commodo ea. Est sit velit veniam velit occaecat non est. Proident eu Lorem excepteur laboris aute.

Enim Lorem incididunt laboris eiusmod irure irure velit esse velit. Reprehenderit quis eiusmod reprehenderit duis. Cillum incididunt minim sint sint cupidatat ut exercitation nulla ullamco proident irure. Velit deserunt irure aliquip esse Lorem nulla minim mollit fugiat cupidatat.

Proident sint irure est irure esse dolore nulla. Incididunt culpa id magna voluptate proident. Lorem laboris aliqua occaecat dolor minim ad fugiat excepteur laborum dolor esse quis fugiat exercitation. Enim Lorem fugiat nostrud veniam.

Excepteur elit non consectetur elit excepteur dolor magna officia occaecat Lorem id id. Voluptate veniam adipisicing quis cupidatat consequat enim consequat non cupidatat veniam in elit reprehenderit nostrud. Elit qui cillum sunt aute cillum enim nostrud amet elit ea duis sint velit. Do magna cillum labore duis non. Tempor laborum ea elit officia aliqua ut aliquip excepteur cupidatat culpa cupidatat velit non ad. Id amet sunt ex culpa veniam elit eu elit.

Exercitation irure irure labore non. Culpa culpa minim deserunt duis est exercitation reprehenderit qui consequat fugiat amet nulla. Consequat sint excepteur incididunt id nostrud sint aute enim enim eiusmod. Ex quis do qui officia laborum pariatur veniam Lorem fugiat ex ad. Id proident anim sint. Irure sit consequat in consectetur dolore deserunt in consectetur cillum elit eiusmod ipsum. In incididunt exercitation proident nisi excepteur sint fugiat ea voluptate quis commodo nostrud nulla sit. Incididunt cillum minim anim excepteur commodo qui do Lorem aliqua deserunt incididunt duis ullamco velit excepteur.

Elit labore commodo consectetur in occaecat ex sunt enim sit cupidatat exercitation ipsum. Exercitation nostrud sint occaecat dolore velit ad ad nostrud. Nisi nulla et exercitation ullamco ad ad nisi laboris qui. Duis culpa nisi ullamco quis deserunt velit sunt mollit amet aute labore.

Irure veniam nostrud id. Ipsum qui proident adipisicing cillum do amet proident esse occaecat elit ullamco velit velit reprehenderit consequat. Reprehenderit velit veniam ea officia anim commodo sit incididunt dolore nostrud laboris ut fugiat. Officia laborum nulla irure do deserunt qui proident quis eu quis esse anim voluptate.</p>
    </detail-layout>
  `,
});
WithStickyHeader.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const WithAlerts = (args, { argTypes }) => ({
  components: { DetailLayout, GlAlert },
  props: Object.keys(argTypes),
  template: `
    <detail-layout v-bind="$props">
      <template #alerts>
        <gl-alert variant="danger" title="Example danger alert title">
          Example alert content
        </gl-alert>
        <gl-alert variant="warning" title="Example warning alert title">
          Example alert content
        </gl-alert>
        <gl-alert variant="info" title="Example info alert title">
          Example alert content
        </gl-alert>
      </template>
      <p>Detail layout default slot.</p>
    </detail-layout>
  `,
});
WithAlerts.args = {
  heading: 'Page Title',
  description: 'This is a page description',
};

export const Loading = Template.bind({});
Loading.args = {
  heading: 'Page Title',
  description: 'This is a page description',
  loading: true,
};

export const PageHeadingSrOnly = Template.bind({});
PageHeadingSrOnly.args = {
  heading: 'Page Title present for screen readers but not visible to sighted users',
  pageHeadingSrOnly: true,
};

export default {
  component: DetailLayout,
  title: 'vue_shared/layouts/detail_layout',
  argTypes: {
    heading: {
      control: 'text',
    },
    description: {
      control: 'text',
    },
    loading: {
      control: 'boolean',
    },
    pageHeadingSrOnly: {
      control: 'boolean',
      description: 'Visually hide with gl-sr-only class',
    },
  },
};
