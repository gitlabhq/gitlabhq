import Vue from 'vue';

export default class SketchRender {
  constructor(browserId, browserPropsId, canvasId, files) {
    this.browserId = browserId;
    this.browserPropsId = browserPropsId;
    this.browserStore = {
      currentPageIndex: 0,
      pages: [],
      activeLayer: '',
      backgroundColor: {
        hex: '#000000',
        rgba: 'rgba(0,0,0,1)'
      },
      hasBackgroundColor: false,
      currentPos: {
        x: 0,
        y: 0,
        width: 0,
        height: 0
      }
    };

    this.files = files;
    if(this.files.hasOwnProperty('document.json')){
      this.files['document.json'].async('string')
       .then(content => this.renderDocument(JSON.parse(content)));
    }

  };

  render() {
    Vue.component('layer', {
      name: 'layer',
      template: 
        `<li class="layer" :class="{artboard: layer._class === 'artboard'}">
          <a href='#' class="expand pull-left" @click.prevent="expand" v-if="layer.layers">
            <span v-if="!expanded">+</span>
            <span v-else>-</span>
          </a>
          <i v-if="layer._class === 'group'" class="fa fa-folder pull-left"></i>
          <i v-if="layer._class === 'text'" class="fa fa-font pull-left"></i>
          <i v-if="layer._class === 'shapeGroup'" class="fa fa-th-large"></i>
          <i v-if="layer._class === 'rectangle'" class="fa fa-square"></i>
          <i v-if="layer._class === 'shapePath'" class="fa fa-heart-o"></i>
          <i v-if="layer._class === 'symbolInstance'" class="fa fa-refresh"></i>
          <i v-if="layer._class === 'symbolMaster'" class="fa fa-refresh"></i>
          <i v-if="layer.isLocked" class="fa fa-lock pull-right"></i>
          <a href='#' @click.prevent="layerSelected(layer)" :title="layer.name">{{layer.name}}</a>
          <ul v-if="layer.layers && expanded">
            <layer :active-layer="activeLayer" :class="{active: activeLayer === layer.do_objectID}" v-for="layer in layer.layers" @layerselected="layerSelected" :key="layer.do_objectID" :layer="layer"></layer>
          </ul>
        </li>`,
      
      props: {
        layer: Object,
        activeLayer: ""
      },

      data() {
        return {
          expanded: false
        }
      },

      methods: {
        expand() {
          this.expanded = !this.expanded;
        },

        layerSelected(layer) {
          this.$emit('layerselected', layer);
        }
      }
    });

    this.vue = new Vue({
      el: `#${this.browserId}`,
      data: this.browserStore,
      computed: {
        currentPage() {
          return this.pages.length ? this.pages[this.currentPageIndex] : {name: 'loading', layers: []};
        }
      },

      methods: {

        rgbToHex(r, g, b) {
          r *= 255;
          g *= 255;
          b *= 255;
          return "#" + ((1 << 24) + (r << 16) + (g << 8) + b).toString(16).slice(1);
        },

        pageSelected(pageIndex) {
          this.currentPageIndex = pageIndex;
          this.browserStore.currentPos.x = this.browserStore.pages[this.currentPageIndex].frame.x;
          this.browserStore.currentPos.y = this.browserStore.pages[this.currentPageIndex].frame.y;
          this.browserStore.currentPos.width = this.browserStore.pages[this.currentPageIndex].frame.width;
          this.browserStore.currentPos.height = this.browserStore.pages[this.currentPageIndex].frame.height;
        },

        setBackgroundColor(bgColor) {
          if(bgColor){
            this.backgroundColor = this.backgroundColor || {};
            this.backgroundColor.hex = this.rgbToHex(bgColor.red, bgColor.green, bgColor.blue);
            bgColor.red = parseInt(bgColor.red * 255);
            bgColor.green = parseInt(bgColor.green * 255);
            bgColor.blue = parseInt(bgColor.blue * 255);
            this.backgroundColor.rgba = `rgba(${bgColor.red}, ${bgColor.green}, ${bgColor.blue}, ${bgColor.alpha})`
          }
        },

        layerSelected(layer) {
          this.currentPos.x = layer.frame.x;
          this.currentPos.y = layer.frame.y;
          this.currentPos.width = layer.frame.width;
          this.currentPos.height = layer.frame.height;
          this.activeLayer = layer.do_objectID;
          this.hasBackgroundColor = layer.hasBackgroundColor;
          this.setBackgroundColor(layer.backgroundColor);
          console.log('layer._class',layer._class);
          console.log('layer',layer);
        }
      }
    });

    this.vuePos = new Vue({
      el: `#${this.browserPropsId}`,
      data: this.browserStore
    });
  };

  storePage(pageJSON) {
    if(pageJSON){
      var page = JSON.parse(pageJSON);
      page.isActive = false;
      this.browserStore.pages.push(page);
    }
  };

  renderDocument(documentJSON) {
    var pages = documentJSON.pages.map(page => `${page._ref}.json`);
    this.currentPageIndex = documentJSON.currentPageIndex;
    pages.reduce((seq, page) => {
      return seq.then((e) => {
        this.storePage(e);
        return this.files[page].async('string');
      });
    }, Promise.resolve())
      .then((e) => {
        this.storePage(e)
        this.browserStore.currentPos.x = this.browserStore.pages[this.currentPageIndex].frame.x;
        this.browserStore.currentPos.y = this.browserStore.pages[this.currentPageIndex].frame.y;
      });
  };
};