import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { STLLoader } from 'three/examples/jsm/loaders/STLLoader';
import * as THREE from 'three';
import MeshObject from './mesh_object';

export default class Renderer {
  constructor(container) {
    this.renderWrapper = this.render.bind(this);
    this.objects = [];

    this.container = container;
    this.width = this.container.offsetWidth;
    this.height = 500;

    this.loader = new STLLoader();

    this.fov = 45;
    this.camera = new THREE.PerspectiveCamera(this.fov, this.width / this.height, 1, 1000);

    this.scene = new THREE.Scene();

    this.scene.add(this.camera);

    // Set up the viewer
    this.setupRenderer();
    this.setupGrid();
    this.setupLight();

    // Set up OrbitControls
    this.controls = new OrbitControls(this.camera, this.renderer.domElement);
    this.controls.minDistance = 5;
    this.controls.maxDistance = 30;
    this.controls.enableKeys = false;

    this.loadFile();
  }

  setupRenderer() {
    this.renderer = new THREE.WebGLRenderer({
      antialias: true,
    });

    this.renderer.setClearColor(0xffffff);
    this.renderer.setPixelRatio(window.devicePixelRatio);
    this.renderer.setSize(this.width, this.height);
  }

  setupLight() {
    // Point light illuminates the object
    const pointLight = new THREE.PointLight(0xffffff, 2, 0);

    pointLight.castShadow = true;

    this.camera.add(pointLight);

    // Ambient light illuminates the scene
    const ambientLight = new THREE.AmbientLight(0xffffff, 1);
    this.scene.add(ambientLight);
  }

  setupGrid() {
    this.grid = new THREE.GridHelper(20, 20, 0x000000, 0x000000);

    this.scene.add(this.grid);
  }

  loadFile() {
    this.loader.load(this.container.dataset.endpoint, (geo) => {
      const obj = new MeshObject(geo);

      this.objects.push(obj);
      this.scene.add(obj);

      this.start();
      this.setDefaultCameraPosition();
    });
  }

  start() {
    // Empty the container first
    this.container.innerHTML = '';

    // Add to DOM
    this.container.appendChild(this.renderer.domElement);

    // Make controls visible
    this.container.parentNode.classList.remove('is-stl-loading');

    this.render();
  }

  render() {
    this.renderer.render(this.scene, this.camera);

    requestAnimationFrame(this.renderWrapper);
  }

  changeObjectMaterials(material) {
    this.objects.forEach((obj) => {
      obj.changeMaterial(material);
    });
  }

  setDefaultCameraPosition() {
    const obj = this.objects[0];
    const radius = obj.geometry.boundingSphere.radius / 1.5;
    const dist = radius / Math.sin((this.fov * (Math.PI / 180)) / 2);

    this.camera.position.set(0, dist + 1, dist);

    this.camera.lookAt(this.grid);
    this.controls.update();
  }
}
