Animations
Only animate opacity & transform properties. Other properties (such as top, left, margin, and padding) all cause Layout to be recalculated, which is much more expensive. For details on this, see "Styles that Affect Layout" in High Performance Animations.

If you do need to change layout (e.g. a sidebar that pushes main content over), prefer FLIP to change expensive properties once, and handle the actual animation with transforms.

